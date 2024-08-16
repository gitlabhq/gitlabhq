# frozen_string_literal: true

class IndexProtectedEnvDeployAccessLevelsOnProtectedEnvProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  INDEX_NAME = 'index_for_protected_environment_project_id_of_protected_environ'

  def up
    add_concurrent_index :protected_environment_deploy_access_levels, :protected_environment_project_id,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :protected_environment_deploy_access_levels, INDEX_NAME
  end
end
