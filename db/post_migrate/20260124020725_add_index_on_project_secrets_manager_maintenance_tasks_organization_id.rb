# frozen_string_literal: true

class AddIndexOnProjectSecretsManagerMaintenanceTasksOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = 'project_secrets_manager_maintenance_tasks'
  INDEX_NAME = 'idx_psm_maintenance_tasks_on_organization_id'

  def up
    add_concurrent_index TABLE_NAME, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
