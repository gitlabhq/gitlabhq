# frozen_string_literal: true

module Cells
  class BulkClaimsWorker
    include ApplicationWorker

    idempotent!
    data_consistency :sticky
    feature_category :cell
    urgency :low
    defer_on_database_health_signal :gitlab_main, [], 1.minute
    # Enough retries with exponential backoff (~8m24s) to handle transient gRPC/network failures
    # https://github.com/sidekiq/sidekiq/wiki/Error-Handling#automatic-job-retry
    sidekiq_options retry: 5
    loggable_arguments 0, 1

    # @param model_name [String] e.g. "RedirectRoute"
    # @param attribute_name [String] e.g. "path"
    # @param payload [Hash] with optional keys:
    #   "create_record_ids" => [Integer] - IDs to load from DB and create claims for
    #   "destroy_metadata"  => [Hash] - pre-built serializable metadata for destroyed records
    def perform(model_name, attribute_name, payload)
      model = model_name.safe_constantize
      attribute = attribute_name.to_sym
      return unless enabled?(model, attribute)

      create_metadata = build_create_metadata(model, attribute, payload)
      destroy_metadata = build_destroy_metadata(payload)
      return if create_metadata.empty? && destroy_metadata.empty?

      result = Cells::Claims::BulkClaimService.new(
        model: model,
        attribute: attribute,
        creates: create_metadata,
        destroys: destroy_metadata
      ).execute

      log_hash_metadata_on_done(
        message: 'Bulk claims worker completed',
        feature_category: :cell,
        model: model_name,
        attribute: attribute_name,
        created: result[:created],
        destroyed: result[:destroyed],
        chunk_count: result[:chunk_count]
      )
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, feature_category: :cell, model: model_name, attribute: attribute_name)
      raise
    end

    private

    def enabled?(model, attribute)
      return false unless model.present? && model < ActiveRecord::Base
      return false unless Cells::Claimable.models_with_claims.include?(model)

      model.cells_claims_enabled_for_attribute?(attribute)
    end

    def build_create_metadata(model, attribute, payload)
      ids = payload['create_record_ids']
      return [] if ids.blank?

      # rubocop:disable CodeReuse/ActiveRecord -- Worker loads records by ID to build claim metadata
      model.where(model.primary_key => ids)
        .filter_map { |record| record.cells_claims_metadata_for_attribute(attribute) }
      # rubocop:enable CodeReuse/ActiveRecord
    end

    def build_destroy_metadata(payload)
      entries = payload['destroy_metadata']
      return [] if entries.blank?

      entries.map do |entry|
        {
          bucket: {
            type: entry['bucket_type'],
            value: entry['bucket_value']
          },
          subject: {
            type: entry['subject_type'],
            id: entry['subject_id']
          },
          source: {
            type: entry['source_type'],
            rails_primary_key_id: Cells::Serialization.to_bytes(entry['primary_key'])
          }
        }
      end
    end
  end
end
