# frozen_string_literal: true

class AddProtectedEnvironmentProjectIdToProtectedEnvironmentApprovalRules < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :protected_environment_approval_rules, :protected_environment_project_id, :bigint
  end
end
