# frozen_string_literal: true

class AddIndexToApprovalRulesOnScanResultPolicyId < Gitlab::Database::Migration[2.1]
  PROJECT_INDEX_NAME = 'idx_approval_project_rules_on_scan_result_policy_id'
  MERGE_REQUEST_INDEX_NAME = 'idx_approval_merge_request_rules_on_scan_result_policy_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :approval_project_rules, :scan_result_policy_id, name: PROJECT_INDEX_NAME
    add_concurrent_index :approval_merge_request_rules, :scan_result_policy_id, name: MERGE_REQUEST_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approval_project_rules, :scan_result_policy_id, name: PROJECT_INDEX_NAME
    remove_concurrent_index_by_name :approval_merge_request_rules, :scan_result_policy_id,
      name: MERGE_REQUEST_INDEX_NAME
  end
end
