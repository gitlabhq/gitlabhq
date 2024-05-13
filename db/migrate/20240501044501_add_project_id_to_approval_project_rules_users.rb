# frozen_string_literal: true

class AddProjectIdToApprovalProjectRulesUsers < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :approval_project_rules_users, :project_id, :bigint
  end
end
