# frozen_string_literal: true

class AddProtectedEnvDeployAccessLevelsProtectedEnvGroupIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    install_sharding_key_assignment_trigger(
      table: :protected_environment_deploy_access_levels,
      sharding_key: :protected_environment_group_id,
      parent_table: :protected_environments,
      parent_sharding_key: :group_id,
      foreign_key: :protected_environment_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :protected_environment_deploy_access_levels,
      sharding_key: :protected_environment_group_id,
      parent_table: :protected_environments,
      parent_sharding_key: :group_id,
      foreign_key: :protected_environment_id
    )
  end
end
