# frozen_string_literal: true

class FixApprovalProjectRulesWithoutProtectedBranches < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 500
  MIGRATION = 'FixApprovalProjectRulesWithoutProtectedBranches'
  INTERVAL = 2.minutes

  def up
    return unless Gitlab.ee?

    queue_batched_background_migration(
      MIGRATION,
      :approval_project_rules,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :approval_project_rules, :id, [])
  end
end
