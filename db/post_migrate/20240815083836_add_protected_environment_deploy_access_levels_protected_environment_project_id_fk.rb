# frozen_string_literal: true

class AddProtectedEnvironmentDeployAccessLevelsProtectedEnvironmentProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :protected_environment_deploy_access_levels, :projects,
      column: :protected_environment_project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :protected_environment_deploy_access_levels, column: :protected_environment_project_id
    end
  end
end
