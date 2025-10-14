# frozen_string_literal: true

module Authn
  module DataRetention
    class OauthAccessTokenArchiveWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- does not perform work scoped to a context

      idempotent!
      deduplicate :until_executing, including_scheduled: true
      data_consistency :sticky
      feature_category :system_access
      concurrency_limit -> { 1 }
      defer_on_database_health_signal :gitlab_main, [:oauth_access_tokens], 5.minutes

      MAX_RUNTIME = 3.minutes
      REQUEUE_DELAY = 3.minutes
      ITERATION_DELAY = 0.1
      BATCH_SIZE = 10_000
      SUB_BATCH_SIZE = 1_000
      CUTOFF_INTERVAL = 1.month

      def perform(cursor = nil)
        return unless Feature.enabled?(:archive_revoked_access_tokens, :instance)

        runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)
        total_archived_count = 0

        # rubocop: disable CodeReuse/ActiveRecord -- We don't want to expose this as a scope until we can provide an index.
        OauthAccessToken.where('id > ?', cursor.to_i).each_batch(of: BATCH_SIZE) do |batch|
          batch.each_batch(of: SUB_BATCH_SIZE) do |sub_batch|
            old_revoked_tokens = sub_batch
                                   .where(revoked_at: ..cutoff_date)
                                   .select(:id)
            # rubocop: enable CodeReuse/ActiveRecord
            sub_batch_count = archive_old_revoked_tokens(old_revoked_tokens)
            log_sub_batch_archived(sub_batch_count)

            total_archived_count += sub_batch_count

            sleep ITERATION_DELAY
          end

          if runtime_limiter.over_time?
            self.class.perform_in(REQUEUE_DELAY, batch.last.id)
            break
          end
        end

        log_extra_metadata_on_done(:result, {
          over_time: runtime_limiter.was_over_time?,
          total_archived: total_archived_count,
          cutoff_date: cutoff_date
        })
      end

      private

      def cutoff_date
        CUTOFF_INTERVAL.ago.beginning_of_day
      end

      def archive_old_revoked_tokens(tokens_to_archive)
        sql = <<~SQL
          WITH deleted AS (
            DELETE FROM oauth_access_tokens
            WHERE id IN (#{tokens_to_archive.to_sql})
            RETURNING *
          )
          INSERT INTO oauth_access_token_archived_records
            (id, resource_owner_id, application_id, token, refresh_token,
             expires_in, revoked_at, created_at, scopes, organization_id, archived_at)
          SELECT
            id, resource_owner_id, application_id, token, refresh_token,
            expires_in, revoked_at, created_at, scopes, organization_id,
            CURRENT_TIMESTAMP as archived_at
          FROM deleted
        SQL

        connection.execute(sql).cmd_tuples
      end

      def connection
        @connection ||= OauthAccessToken.connection
      end

      def log_sub_batch_archived(count)
        return if count == 0

        Gitlab::AppLogger.info(
          class: self.class.name,
          message: "Archived OAuth tokens sub-batch",
          sub_batch_archived: count,
          cutoff_date: cutoff_date
        )
      end
    end
  end
end
