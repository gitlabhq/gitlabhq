# frozen_string_literal: true

class RequeueBackfillApprovalProjectRulesProtectedBranchesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillApprovalProjectRulesProtectedBranchesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  SUB_BATCH_SIZE = 500
  TABLE_NAME = :approval_project_rules_protected_branches
  BATCH_COLUMN = :approval_project_rule_id
  JOB_ARGS = %i[project_id approval_project_rules project_id approval_project_rule_id]

  def up
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, JOB_ARGS)

    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      *JOB_ARGS,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, JOB_ARGS)
  end
end
