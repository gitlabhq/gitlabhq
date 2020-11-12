# frozen_string_literal: true

class ScheduleMergeRequestCleanupSchedulesBackfill < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'BackfillMergeRequestCleanupSchedules'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  TEMP_INDEX_NAME = 'merge_requests_state_id_temp_index'

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, :id, name: TEMP_INDEX_NAME, where: "state_id IN (2, 3)"

    eligible_mrs = Gitlab::BackgroundMigration::BackfillMergeRequestCleanupSchedules::MergeRequest.eligible

    queue_background_migration_jobs_by_range_at_intervals(
      eligible_mrs,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    remove_concurrent_index_by_name :merge_requests, TEMP_INDEX_NAME
  end
end
