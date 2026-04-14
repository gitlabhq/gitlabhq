# frozen_string_literal: true

module Cells
  class ClaimsVerificationWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers

    # Enough retries with exponential backoff (~8m24s) to outlast a stale exclusive lease (LEASE_TIMEOUT)
    # https://github.com/sidekiq/sidekiq/wiki/Error-Handling#automatic-job-retry
    sidekiq_options retry: 5
    data_consistency :sticky
    feature_category :cell
    urgency :throttled
    loggable_arguments 0
    idempotent!

    LEASE_TIMEOUT = 5.minutes
    MAX_RUNTIME = 4.minutes + 30.seconds
    REDIS_LAST_PROCESSED_ID_TTL = 3.days

    def perform(model_name)
      @model_name = model_name

      model = model_name.safe_constantize
      return unless model.present? && model < ActiveRecord::Base
      return unless enabled?(model)

      result = nil

      # Don't retry obtaining lock in-process. Fail fast and let Sidekiq retry so the thread is freed for other jobs
      in_lock(lease_key, ttl: LEASE_TIMEOUT, retries: 0) do
        start_id = last_processed_id
        result = Cells::Claims::VerificationService.new(
          model, timeout: MAX_RUNTIME, start_id: start_id
        ) { |batch_last_id| save_last_processed_id(batch_last_id) }.execute

        save_last_processed_id(0) unless result[:over_time]

        log_hash_metadata_on_done(
          message: 'Records verification completed',
          feature_category: :cell,
          model: model_name,
          created: result[:created],
          destroyed: result[:destroyed],
          over_time: result[:over_time],
          start_id: start_id,
          last_id: result[:last_id]
        )
      end

      self.class.perform_async(model_name) if result&.dig(:over_time)
    rescue FailedToObtainLockError
      Sidekiq.logger.warn(
        message: 'Could not obtain exclusive lease, retrying via Sidekiq internal retry',
        lease_key: lease_key,
        lease_ttl: LEASE_TIMEOUT
      )
      raise
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, feature_category: :cell)
      raise
    end

    private

    def lease_key
      "#{self.class.name.underscore}:#{@model_name}"
    end

    def last_processed_id
      Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key).to_i }
    end

    def save_last_processed_id(id)
      Gitlab::Redis::SharedState.with { |redis| redis.set(redis_key, id, ex: REDIS_LAST_PROCESSED_ID_TTL) }
    end

    def redis_key
      "cells:claims:verification_service:last_processed_id:#{@model_name}"
    end

    def enabled?(model)
      Gitlab.config.cell.enabled &&
        Feature.enabled?("cells_claims_verification_worker_#{Gitlab::Utils.param_key(model)}", # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- Need to check against model names dynamically
          :instance)
    end
  end
end
