# frozen_string_literal: true

class AddProtectedEnvironmentGroupIdToProtectedEnvironmentDeployAccessLevels < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :protected_environment_deploy_access_levels, :protected_environment_group_id, :bigint
  end
end
