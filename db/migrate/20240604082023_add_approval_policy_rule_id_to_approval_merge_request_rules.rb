# frozen_string_literal: true

class AddApprovalPolicyRuleIdToApprovalMergeRequestRules < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.1'

  def up
    add_column :approval_merge_request_rules, :approval_policy_rule_id, :bigint
  end

  def down
    remove_column :approval_merge_request_rules, :approval_policy_rule_id
  end
end
