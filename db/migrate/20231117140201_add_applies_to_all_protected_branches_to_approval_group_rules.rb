# frozen_string_literal: true

class AddAppliesToAllProtectedBranchesToApprovalGroupRules < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def up
    add_column :approval_group_rules, :applies_to_all_protected_branches, :boolean, default: false, null: false
  end

  def down
    remove_column :approval_group_rules, :applies_to_all_protected_branches
  end
end
