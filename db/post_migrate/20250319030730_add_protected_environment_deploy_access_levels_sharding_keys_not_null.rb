# frozen_string_literal: true

class AddProtectedEnvironmentDeployAccessLevelsShardingKeysNotNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_multi_column_not_null_constraint(
      :protected_environment_deploy_access_levels,
      :protected_environment_project_id,
      :protected_environment_group_id
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :protected_environment_deploy_access_levels,
      :protected_environment_project_id,
      :protected_environment_group_id
    )
  end
end
