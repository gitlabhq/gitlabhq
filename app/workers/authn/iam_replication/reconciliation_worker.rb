# frozen_string_literal: true

module Authn
  module IamReplication
    class ReconciliationWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- instance-wide sweep, no context

      idempotent!
      deduplicate :until_executed, including_scheduled: true
      # Replicas may lag up to 60s, the Layer 3 delay: a stale read could overwrite a newer Layer 3 write.
      data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- see comment above
      feature_category :system_access
      urgency :low
      worker_has_external_dependencies!
      # TODO: use ::Authn::IamOutbox::ALLOWED_ENTITY_TYPES.size when a second entity type is added,
      # so the sweeps do not block each other: https://gitlab.com/gitlab-org/gitlab/-/work_items/632068
      concurrency_limit -> { 1 }
      loggable_arguments 0
      defer_on_database_health_signal :gitlab_main, [:oauth_applications], 5.minutes

      # Shorter than the cron interval (5 minutes), so runs do not overlap.
      MAX_RUNTIME = 4.minutes
      BATCH_SIZE = 200
      REDIS_LAST_PROCESSED_ID_TTL = 14.days
      # Any other reason means IAM is unhealthy: re-raise, and the next run retries from the last processed id.
      ROW_LEVEL_REASONS = %i[invalid_request].freeze

      def perform(entity_type)
        return unless ::Authn::IamReplication.enabled? && ::Authn::IamAuthService.enabled?

        @entity_type = entity_type
        @replicator = ::Authn::IamReplication.replicator_for(entity_type).new
        runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)
        counts = Hash.new(0)

        begin
          # rubocop:disable CodeReuse/ActiveRecord -- scan owned by this worker
          replicator.class.reconciliation_scope.where('id > ?', last_processed_id).each_batch(of: BATCH_SIZE) do |batch|
            # each_batch drops ORDER BY; order so records.last is the highest id of the batch.
            records = batch.order(:id)
            # rubocop:enable CodeReuse/ActiveRecord
            records.each { |record| counts[upsert(record)] += 1 }
            save_last_processed_id(records.last.id) if records.any?

            break if runtime_limiter.over_time?
          end

          # Not over time means each_batch ran out of rows: the pass is complete, so the next run starts over.
          save_last_processed_id(0) unless runtime_limiter.was_over_time?
        ensure
          # In ensure, so a run that IAM stops also logs how far it got.
          log_extra_metadata_on_done(:result, counts.merge(
            entity_type: entity_type,
            layer: 4,
            cell_id: Gitlab.config.cell.id.to_i,
            over_time: runtime_limiter.was_over_time?
          ))
        end
      end

      private

      attr_reader :entity_type, :replicator

      def upsert(record)
        replicator.upsert(record)
      rescue ::Authn::IamService::GrpcClient::RequestError => error
        raise unless ROW_LEVEL_REASONS.include?(error.reason)

        log_skipped_row(record, error.reason)
        error.reason
      rescue StandardError => error
        Gitlab::ErrorTracking.track_exception(error, entity_type: entity_type, entity_id: record.id)
        :error
      end

      def log_skipped_row(record, reason)
        ::Gitlab::AuthLogger.warn(
          build_structured_payload_labkit(
            message: 'IAM reconciliation row skipped',
            layer: 4,
            entity_type: entity_type,
            entity_id: record.id,
            skip_reason: reason
          )
        )
      end

      def last_processed_id
        Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key).to_i }
      end

      def save_last_processed_id(processed_id)
        Gitlab::Redis::SharedState.with { |redis| redis.set(redis_key, processed_id, ex: REDIS_LAST_PROCESSED_ID_TTL) }
      end

      def redis_key
        "authn:iam_replication:reconciliation:last_processed_id:#{entity_type}"
      end
    end
  end
end
