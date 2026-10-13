# frozen_string_literal: true

class QueueBackfillMissedDiffCommitsToPartitioned < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'BackfillMissedDiffCommitsToPartitioned'

  # merge_request_diff_commits_archived is the pre-partitioning table and merge_request_diff_commits
  # the partitioned one - names true only where SwapMergeRequestDiffCommitsTable ran, hence .com only.
  SOURCE_TABLE = :merge_request_diff_commits_archived
  TARGET_TABLE = :merge_request_diff_commits

  # Insert cost varies across the window, so the optimizer would grow batches in the sparse regions
  # well past what the dense ones can run within the interval.
  BATCH_SIZE = 250_000
  SUB_BATCH_SIZE = 5_000
  MAX_BATCH_SIZE = 1_000_000

  # merge_request_diff_commits_dedup flag was first enabled in production on 2025-11-03 15:08:03 UTC;
  # before that no row could carry the shape the original backfill excluded, so none can be missing.
  MIN_DIFF_ID = 1_548_627_880

  # 3c7ae0dac948 (2026-06-22) removed flag merge_request_diff_commits_partition, which gated the forward
  # sync trigger. That trigger copies rows where merge_request_commits_metadata_id and project_id are
  # both non-NULL, so rows above this cursor are correct by construction.
  MAX_DIFF_ID = 1_879_503_824

  # A diff cannot hold more than 1,000,000 commits, so this caps the cursor at MAX_DIFF_ID without
  # querying the table for its real maximum relative_order.
  MAX_RELATIVE_ORDER = 999_999

  # Without this, queue_batched_background_migration derives total_tuple_count from the whole
  # archived table, far larger than this cursor window, making every progress estimate wrong.
  TUPLE_COUNT = 3_351_569_145

  def up
    return unless Gitlab.com_except_jh?

    migration = queue_batched_background_migration(
      MIGRATION,
      SOURCE_TABLE,
      :merge_request_diff_id,
      TARGET_TABLE,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      min_cursor: [MIN_DIFF_ID, 0],
      max_cursor: [MAX_DIFF_ID, MAX_RELATIVE_ORDER]
    )

    migration&.update!(total_tuple_count: TUPLE_COUNT)
  end

  def down
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(
      MIGRATION,
      SOURCE_TABLE,
      :merge_request_diff_id,
      [TARGET_TABLE]
    )
  end
end
