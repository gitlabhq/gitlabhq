# frozen_string_literal: true

module Authn
  module DataRetention
    class OauthAccessGrantArchiveWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- does not perform work scoped to a context

      idempotent!
      deduplicate :until_executing, including_scheduled: true
      data_consistency :sticky
      feature_category :system_access
      concurrency_limit -> { 1 }
      defer_on_database_health_signal :gitlab_main, [:oauth_access_grants], 5.minutes

      MAX_RUNTIME = 3.minutes
      REQUEUE_DELAY = 3.minutes
      ITERATION_DELAY = 0.1
      BATCH_SIZE = 10_000
      SUB_BATCH_SIZE = 1_000
      CUTOFF_INTERVAL = 1.month

      def perform(cursor = nil)
        return unless Gitlab::CurrentSettings.authn_data_retention_cleanup_enabled?
        return unless Feature.enabled?(:archive_revoked_access_grants, :instance)

        runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)
        total_deleted_count = 0

        # rubocop: disable CodeReuse/ActiveRecord -- We don't want to expose this as a scope until we can provide an index.
        OauthAccessGrant.where('id > ?', cursor.to_i).each_batch(of: BATCH_SIZE) do |batch|
          batch.each_batch(of: SUB_BATCH_SIZE) do |sub_batch|
            old_revoked_grants = sub_batch
                                   .where(revoked_at: ..cutoff_date)
                                   .select(:id)
            # rubocop: enable CodeReuse/ActiveRecord
            sub_batch_count = old_revoked_grants.delete_all
            log_sub_batch_deleted(sub_batch_count)

            total_deleted_count += sub_batch_count

            sleep ITERATION_DELAY
          end

          if runtime_limiter.over_time?
            self.class.perform_in(REQUEUE_DELAY, batch.last.id)
            break
          end
        end

        log_extra_metadata_on_done(:result, {
          over_time: runtime_limiter.was_over_time?,
          total_deleted: total_deleted_count,
          cutoff_date: cutoff_date
        })
      end

      private

      def cutoff_date
        OauthAccessGrant::RETENTION_PERIOD.ago.beginning_of_day
      end

      def connection
        @connection ||= OauthAccessGrant.connection
      end

      def log_sub_batch_deleted(count)
        return if count == 0

        Gitlab::AppLogger.info(
          class: self.class.name,
          message: "Deleted OAuth grants sub-batch",
          sub_batch_deleted: count,
          cutoff_date: cutoff_date
        )
      end
    end
  end
end
