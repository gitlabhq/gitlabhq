# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill merge request cleanup schedules of closed/merged merge requests
    # without any corresponding records.
    class BackfillMergeRequestCleanupSchedules
      # Model used for migration added in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/46782.
      class MergeRequest < ActiveRecord::Base
        include EachBatch

        self.table_name = 'merge_requests'

        def self.eligible
          where('merge_requests.state_id IN (2, 3)')
        end
      end

      def perform(start_id, end_id)
        eligible_mrs = MergeRequest.eligible.where(id: start_id..end_id)
        scheduled_at_column = "COALESCE(metrics.merged_at, COALESCE(metrics.latest_closed_at, merge_requests.updated_at)) + interval '14 days'"
        query =
          eligible_mrs
            .select("merge_requests.id, #{scheduled_at_column}, NOW(), NOW()")
            .joins('LEFT JOIN merge_request_metrics metrics ON metrics.merge_request_id = merge_requests.id')

        result = ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO merge_request_cleanup_schedules (merge_request_id, scheduled_at, created_at, updated_at)
          #{query.to_sql}
          ON CONFLICT (merge_request_id) DO NOTHING;
        SQL

        ::Gitlab::BackgroundMigration::Logger.info(
          message: 'Backfilled merge_request_cleanup_schedules records',
          count: result.cmd_tuples
        )
      end
    end
  end
end
