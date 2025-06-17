# frozen_string_literal: true

class AddApprovalProjectRulesProtectedBranchesProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :approval_project_rules_protected_branches, :project_id
  end

  def down
    remove_not_null_constraint :approval_project_rules_protected_branches, :project_id
  end
end
