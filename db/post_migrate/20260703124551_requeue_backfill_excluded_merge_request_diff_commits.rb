# frozen_string_literal: true

class RequeueBackfillExcludedMergeRequestDiffCommits < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_local

  MIGRATION = 'BackfillExcludedMergeRequestDiffCommits'
  BATCH_SIZE = 1
  SUB_BATCH_SIZE = 1
  MAX_BATCH_SIZE = 1

  def up
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :excluded_merge_requests, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :excluded_merge_requests,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :excluded_merge_requests, :id, [])
  end
end
