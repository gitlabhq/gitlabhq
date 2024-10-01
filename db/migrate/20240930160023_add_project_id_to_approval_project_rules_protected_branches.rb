# frozen_string_literal: true

class AddProjectIdToApprovalProjectRulesProtectedBranches < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :approval_project_rules_protected_branches, :project_id, :bigint
  end
end
