# frozen_string_literal: true

class AddApprovalGroupRulesProtectedBranchesGroupIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :approval_group_rules_protected_branches, :group_id
  end

  def down
    remove_not_null_constraint :approval_group_rules_protected_branches, :group_id
  end
end
