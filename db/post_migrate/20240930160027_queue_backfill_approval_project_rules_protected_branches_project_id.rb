# frozen_string_literal: true

class QueueBackfillApprovalProjectRulesProtectedBranchesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillApprovalProjectRulesProtectedBranchesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :approval_project_rules_protected_branches,
      :approval_project_rule_id,
      :project_id,
      :approval_project_rules,
      :project_id,
      :approval_project_rule_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      batch_class_name: 'LooseIndexScanBatchingStrategy',
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :approval_project_rules_protected_branches,
      :approval_project_rule_id,
      [
        :project_id,
        :approval_project_rules,
        :project_id,
        :approval_project_rule_id
      ]
    )
  end
end
