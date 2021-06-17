# frozen_string_literal: true

class ScheduleBackfillDraftStatusOnMergeRequests < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = "tmp_index_merge_requests_draft_and_status"
  MIGRATION = 'BackfillDraftStatusOnMergeRequests'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 100

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, :id,
      where: "draft = false AND state_id = 1 AND ((title)::text ~* '^\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP'::text)",
      name: INDEX_NAME

    eligible_mrs = Gitlab::BackgroundMigration::BackfillDraftStatusOnMergeRequests::MergeRequest.eligible

    queue_background_migration_jobs_by_range_at_intervals(
      eligible_mrs,
      MIGRATION,
      DELAY_INTERVAL,
      track_jobs: true,
      batch_size: BATCH_SIZE
    )
  end

  def down
    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end
end
