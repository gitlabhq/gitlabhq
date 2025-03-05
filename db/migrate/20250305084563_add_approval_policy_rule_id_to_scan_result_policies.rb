# frozen_string_literal: true

class AddApprovalPolicyRuleIdToScanResultPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :scan_result_policies, :approval_policy_rule_id, :bigint
  end
end
