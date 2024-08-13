# frozen_string_literal: true

class AddGroupIdToApprovalGroupRulesProtectedBranches < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :approval_group_rules_protected_branches, :group_id, :bigint
  end
end
