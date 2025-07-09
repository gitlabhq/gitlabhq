# frozen_string_literal: true

class FinalizeBackfillApprovalMergeRequestRulesApprovedApproversProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillApprovalMergeRequestRulesApprovedApproversProjectId',
      table_name: :approval_merge_request_rules_approved_approvers,
      column_name: :id,
      job_arguments: [:project_id, :approval_merge_request_rules, :project_id, :approval_merge_request_rule_id],
      finalize: true
    )
  end

  def down; end
end
