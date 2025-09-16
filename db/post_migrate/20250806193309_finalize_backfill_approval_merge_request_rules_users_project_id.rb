# frozen_string_literal: true

class FinalizeBackfillApprovalMergeRequestRulesUsersProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillApprovalMergeRequestRulesUsersProjectId',
      table_name: :approval_merge_request_rules_users,
      column_name: :id,
      job_arguments: [:project_id, :approval_merge_request_rules, :project_id, :approval_merge_request_rule_id],
      finalize: true
    )
  end

  def down; end
end
