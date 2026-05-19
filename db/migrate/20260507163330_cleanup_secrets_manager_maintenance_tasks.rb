# frozen_string_literal: true

class CleanupSecretsManagerMaintenanceTasks < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_local
  disable_ddl_transaction!

  milestone '19.0'

  def up
    execute('DELETE FROM project_secrets_manager_maintenance_tasks')
    execute('DELETE FROM group_secrets_manager_maintenance_tasks')
  end

  def down
    # no-op: closed-beta data cannot be restored
  end
end
