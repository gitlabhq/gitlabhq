# frozen_string_literal: true

class QueueBackfillProtectedBranchUnprotectAccessLevelsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillProtectedBranchUnprotectAccessLevelsProtectedBranchProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :protected_branch_unprotect_access_levels,
      :id,
      :protected_branch_project_id,
      :protected_branches,
      :project_id,
      :protected_branch_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :protected_branch_unprotect_access_levels,
      :id,
      [
        :protected_branch_project_id,
        :protected_branches,
        :project_id,
        :protected_branch_id
      ]
    )
  end
end
