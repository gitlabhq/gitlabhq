# frozen_string_literal: true

class AddForeignKeyOnProjectSecretsManagerMaintenanceTasksOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = 'project_secrets_manager_maintenance_tasks'

  def up
    add_concurrent_foreign_key TABLE_NAME,
      :organizations,
      column: :organization_id,
      on_delete: :cascade,
      validate: true
  end

  def down
    remove_foreign_key_if_exists TABLE_NAME, :organizations, column: :organization_id
  end
end
