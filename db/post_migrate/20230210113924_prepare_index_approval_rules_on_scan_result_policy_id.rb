# frozen_string_literal: true

class PrepareIndexApprovalRulesOnScanResultPolicyId < Gitlab::Database::Migration[2.1]
  PROJECT_INDEX_NAME = 'idx_approval_project_rules_on_scan_result_policy_id'
  MERGE_REQUEST_INDEX_NAME = 'idx_approval_merge_request_rules_on_scan_result_policy_id'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/391312
  def up
    prepare_async_index :approval_project_rules, :scan_result_policy_id, name: PROJECT_INDEX_NAME
    prepare_async_index :approval_merge_request_rules, :scan_result_policy_id, name: MERGE_REQUEST_INDEX_NAME
  end

  def down
    unprepare_async_index :approval_project_rules, :scan_result_policy_id, name: PROJECT_INDEX_NAME
    unprepare_async_index :approval_merge_request_rules, :scan_result_policy_id, name: MERGE_REQUEST_INDEX_NAME
  end
end
