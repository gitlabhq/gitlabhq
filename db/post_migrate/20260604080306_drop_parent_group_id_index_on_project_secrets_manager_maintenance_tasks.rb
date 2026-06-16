# frozen_string_literal: true

class DropParentGroupIdIndexOnProjectSecretsManagerMaintenanceTasks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  INDEX_NAME = 'idx_psm_maintenance_tasks_on_parent_group_id'

  def up
    remove_concurrent_index_by_name :project_secrets_manager_maintenance_tasks, INDEX_NAME
  end

  def down
    add_concurrent_index :project_secrets_manager_maintenance_tasks, :parent_group_id, name: INDEX_NAME
  end
end
