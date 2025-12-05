# frozen_string_literal: true

module Authn
  module DataRetention
    class AuthenticationEventArchiveWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- does not require context

      idempotent!
      deduplicate :until_executing, including_scheduled: true
      data_consistency :sticky
      feature_category :system_access
      concurrency_limit -> { 1 }
      defer_on_database_health_signal :gitlab_main, [:authentication_events], 5.minutes

      MAX_RUNTIME = 3.minutes
      REQUEUE_DELAY = 3.minutes
      ITERATION_DELAY = 0.1
      BATCH_SIZE = 10_000
      SUB_BATCH_SIZE = 1_000

      def perform(cursor = nil)
        return unless Gitlab::CurrentSettings.authn_data_retention_cleanup_enabled?
        return unless Feature.enabled?(:archive_authentication_events, :instance)

        runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)
        total_deleted_count = 0

        # rubocop: disable CodeReuse/ActiveRecord -- not a useful scope for re-use
        AuthenticationEvent.where('id > ?', cursor.to_i).each_batch(of: BATCH_SIZE) do |batch|
          # rubocop: enable CodeReuse/ActiveRecord
          last_id_in_batch = batch.last.id

          batch.each_batch(of: SUB_BATCH_SIZE) do |sub_batch|
            events_to_delete = sub_batch

            count = delete_old_events(events_to_delete)

            total_deleted_count += count

            log_deleted(count)

            sleep ITERATION_DELAY
          end

          if runtime_limiter.over_time?
            self.class.perform_in(REQUEUE_DELAY, last_id_in_batch)
            break
          end
        end

        log_extra_metadata_on_done(:result, {
          over_time: runtime_limiter.was_over_time?,
          total_deleted: total_deleted_count,
          cutoff_time: retention_period_cutoff
        })
      end

      private

      def delete_old_events(events)
        return 0 unless events.exists?

        sql = <<~SQL
          WITH batch AS MATERIALIZED (
                #{events.select(:id, :created_at).limit(SUB_BATCH_SIZE).to_sql}
            ),
            filtered_batch AS MATERIALIZED (
              SELECT id, created_at FROM batch
              WHERE created_at <= '#{retention_period_cutoff.to_fs(:db)}' LIMIT #{SUB_BATCH_SIZE}
            )
            DELETE FROM authentication_events
            WHERE id IN (SELECT id FROM filtered_batch)
        SQL

        connection.execute(sql).cmd_tuples
      end

      def connection
        @connection ||= AuthenticationEvent.connection
      end

      def log_deleted(count)
        return if count == 0

        Gitlab::AppLogger.info(
          class: self.class.name,
          message: "Deleted #{count} authentication events",
          cutoff_time: retention_period_cutoff
        )
      end

      def retention_period_cutoff
        AuthenticationEvent::RETENTION_PERIOD.ago.beginning_of_day
      end
    end
  end
end
