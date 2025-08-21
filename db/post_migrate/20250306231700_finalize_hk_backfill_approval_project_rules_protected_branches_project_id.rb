# frozen_string_literal: true

class FinalizeHkBackfillApprovalProjectRulesProtectedBranchesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillApprovalProjectRulesProtectedBranchesProjectId',
      table_name: :approval_project_rules_protected_branches,
      column_name: :approval_project_rule_id,
      job_arguments: [:project_id, :approval_project_rules, :project_id, :approval_project_rule_id],
      finalize: true
    )
  end

  def down; end
end
