# frozen_string_literal: true

class QueueDeleteInvalidProtectedBranchMergeAccessLevels < Gitlab::Database::Migration[2.1]
  MIGRATION = "DeleteInvalidProtectedBranchMergeAccessLevels"
  DELAY_INTERVAL = 2.minutes
  MAX_BATCH_SIZE = 10_000
  BATCH_SIZE = 5_000
  SUB_BATCH_SIZE = 500

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :protected_branch_merge_access_levels,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :protected_branch_merge_access_levels, :id, [])
  end
end
