# frozen_string_literal: true

class AddRuleIdFkToApprovalPolicyRuleProjectLinks < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :approval_policy_rule_project_links, :approval_policy_rules,
      column: :approval_policy_rule_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :approval_policy_rule_project_links, column: :approval_policy_rule_id
    end
  end
end
