# frozen_string_literal: true

class IndexApprovalMergeRequestRulesApprovedApproversOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_approval_merge_request_rules_approved_approvers_project_id'

  def up
    add_concurrent_index :approval_merge_request_rules_approved_approvers, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rules_approved_approvers, INDEX_NAME
  end
end
