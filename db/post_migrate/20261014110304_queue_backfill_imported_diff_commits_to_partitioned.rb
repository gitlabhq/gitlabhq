# frozen_string_literal: true

class QueueBackfillImportedDiffCommitsToPartitioned < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'BackfillImportedDiffCommitsToPartitioned'
  BATCH_TABLE = :merge_request_diffs
  BATCH_COLUMN = :id

  # merge_request_diff_commits_archived is the pre-partitioning table and merge_request_diff_commits
  # the partitioned one - names true only where SwapMergeRequestDiffCommitsTable ran, hence .com only.
  SOURCE_TABLE = 'merge_request_diff_commits_archived'
  TARGET_TABLE = 'merge_request_diff_commits'

  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 200
  MAX_BATCH_SIZE = 50_000

  # Projects created from 2021-07-07 (!63669 merged) to 2021-11-10 (!74031 deployed on 2021-11-09 plus margin).
  # projects.created_at is set when the import starts, unlike merge_request_diffs.created_at.
  MIN_PROJECT_ID = 27_951_444 # 2021-07-07 00:00:02 UTC
  MAX_PROJECT_ID = 31_189_569 # 2021-11-09 23:59:46 UTC

  # Diffs inserted over the same window, with ~4 weeks of slack past the 2021-11-09 bug fix.
  # The NULL user-ID defect only existed in the importer during that window, so diffs outside
  # these bounds have real user IDs and are excluded by the inner project-ID filter anyway.
  MIN_DIFF_ID = 211_000_000 # inserted around 2021-07-06
  MAX_DIFF_ID = 288_000_000 # inserted around 2021-12-01

  # Diffs in the cursor range, counted on Database Lab. Without it, total_tuple_count would cover the whole table.
  TUPLE_COUNT = 48_032_180

  def up
    return unless Gitlab.com_except_jh?

    migration = queue_batched_background_migration(
      MIGRATION,
      BATCH_TABLE,
      BATCH_COLUMN,
      SOURCE_TABLE,
      TARGET_TABLE,
      MIN_PROJECT_ID,
      MAX_PROJECT_ID,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      min_cursor: [MIN_DIFF_ID],
      max_cursor: [MAX_DIFF_ID]
    )

    migration&.update!(total_tuple_count: TUPLE_COUNT)
  end

  def down
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(
      MIGRATION,
      BATCH_TABLE,
      BATCH_COLUMN,
      [SOURCE_TABLE, TARGET_TABLE, MIN_PROJECT_ID, MAX_PROJECT_ID]
    )
  end
end
