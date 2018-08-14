class MigrateRemainingMrMetricsPopulatingBackgroundMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 5_000
  MIGRATION = 'PopulateMergeRequestMetricsWithEventsData'
  DELAY_INTERVAL = 10.minutes

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'

    include ::EachBatch
  end

  def up
    # Perform any ongoing background migration that might still be running. This
    # avoids scheduling way too many of the same jobs on self-hosted instances
    # if they're updating GitLab across multiple versions. The "Take one"
    # migration was executed on 10.4 on
    # SchedulePopulateMergeRequestMetricsWithEventsData.
    Gitlab::BackgroundMigration.steal(MIGRATION)

    metrics_not_exists_clause = <<~SQL
      NOT EXISTS (SELECT 1 FROM merge_request_metrics
                  WHERE merge_request_metrics.merge_request_id = merge_requests.id)
    SQL

    relation = MergeRequest.where(metrics_not_exists_clause)

    # We currently have ~400_000 MR records without metrics on GitLab.com.
    # This means it'll schedule ~80 jobs (5000 MRs each) with a 10 minutes gap,
    # so this should take ~14 hours for all background migrations to complete.
    #
    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          MIGRATION,
                                                          DELAY_INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
  end
end
