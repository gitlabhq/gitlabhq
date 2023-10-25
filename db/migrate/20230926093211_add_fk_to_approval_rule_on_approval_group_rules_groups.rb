# frozen_string_literal: true

class AddFkToApprovalRuleOnApprovalGroupRulesGroups < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :approval_group_rules_groups, :approval_group_rules, column: :approval_group_rule_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :approval_group_rules_groups, column: :approval_group_rule_id
    end
  end
end
