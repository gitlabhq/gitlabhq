# frozen_string_literal: true

class ScheduleBackfillDraftStatusOnMergeRequestsCorrectedRegex < Gitlab::Database::Migration[1.0]
  INDEX_NAME = "tmp_index_merge_requests_draft_and_status"
  MIGRATION = "BackfillDraftStatusOnMergeRequestsWithCorrectedRegex"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50
  CORRECTED_REGEXP_STR = "^(\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP)"

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, :id,
      where: "draft = false AND state_id = 1 AND ((title)::text ~* '#{CORRECTED_REGEXP_STR}'::text)",
      name: INDEX_NAME

    eligible_mrs = MergeRequest.where(state_id: 1)
    .where(draft: false)
    .where("title ~* ?", CORRECTED_REGEXP_STR)

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
