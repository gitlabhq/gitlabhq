# frozen_string_literal: true

class AddApprovalPolicyRuleIdToScanResultPolicyViolations < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.1'

  def up
    add_column :scan_result_policy_violations, :approval_policy_rule_id, :bigint
  end

  def down
    remove_column :scan_result_policy_violations, :approval_policy_rule_id
  end
end
