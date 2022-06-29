# frozen_string_literal: true

class AddAppliesToAllProtectedBranchesToApprovalProjectRule < Gitlab::Database::Migration[2.0]
  def change
    add_column :approval_project_rules, :applies_to_all_protected_branches, :boolean, default: false, null: false
  end
end
