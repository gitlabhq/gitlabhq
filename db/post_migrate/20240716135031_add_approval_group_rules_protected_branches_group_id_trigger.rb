# frozen_string_literal: true

class AddApprovalGroupRulesProtectedBranchesGroupIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :approval_group_rules_protected_branches,
      sharding_key: :group_id,
      parent_table: :approval_group_rules,
      parent_sharding_key: :group_id,
      foreign_key: :approval_group_rule_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :approval_group_rules_protected_branches,
      sharding_key: :group_id,
      parent_table: :approval_group_rules,
      parent_sharding_key: :group_id,
      foreign_key: :approval_group_rule_id
    )
  end
end
