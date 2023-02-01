# frozen_string_literal: true

class RemoveProtectedEnvironmentDefaultAccessLevel < Gitlab::Database::Migration[2.1]
  def change
    change_column_default :protected_environment_deploy_access_levels, :access_level, from: 40, to: nil
  end
end
