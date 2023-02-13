# frozen_string_literal: true

class AddScanResultPolicyIdToApprovalRules < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :approval_project_rules, :scan_result_policy_id, :bigint
    add_column :approval_merge_request_rules, :scan_result_policy_id, :bigint
  end
end
