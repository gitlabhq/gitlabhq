class ScheduleMergeRequestDiffMigrationsTakeTwo < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 500
  MIGRATION = 'DeserializeMergeRequestDiffsAndCommits'
  DELAY_INTERVAL = 10.minutes

  disable_ddl_transaction!

  class MergeRequestDiff < ActiveRecord::Base
    self.table_name = 'merge_request_diffs'

    include ::EachBatch

    default_scope { where('st_commits IS NOT NULL OR st_diffs IS NOT NULL') }
  end

  # By this point, we assume ScheduleMergeRequestDiffMigrations - the first
  # version of this - has already run. On GitLab.com, we have ~220k un-migrated
  # rows, but these rows will, in general, take a long time.
  #
  # With a gap of 10 minutes per batch, and 500 rows per batch, these migrations
  # are scheduled over 220_000 / 500 / 6 ~= 74 hours, which is a little over
  # three days.
  def up
    queue_background_migration_jobs_by_range_at_intervals(MergeRequestDiff, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
  end
end
