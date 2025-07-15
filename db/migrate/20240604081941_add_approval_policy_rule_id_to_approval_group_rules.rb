# frozen_string_literal: true

class AddApprovalPolicyRuleIdToApprovalGroupRules < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    add_column :approval_group_rules, :approval_policy_rule_id, :bigint
  end

  def down
    remove_column :approval_group_rules, :approval_policy_rule_id
  end
end
