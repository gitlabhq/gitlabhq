# frozen_string_literal: true

class AddProtectedEnvironmentApprovalRulesProtectedEnvironmentProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    install_sharding_key_assignment_trigger(
      table: :protected_environment_approval_rules,
      sharding_key: :protected_environment_project_id,
      parent_table: :protected_environments,
      parent_sharding_key: :project_id,
      foreign_key: :protected_environment_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :protected_environment_approval_rules,
      sharding_key: :protected_environment_project_id,
      parent_table: :protected_environments,
      parent_sharding_key: :project_id,
      foreign_key: :protected_environment_id
    )
  end
end
