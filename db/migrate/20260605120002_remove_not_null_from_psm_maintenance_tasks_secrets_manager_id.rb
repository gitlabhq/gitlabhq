# frozen_string_literal: true

class RemoveNotNullFromPsmMaintenanceTasksSecretsManagerId < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    change_column_null :project_secrets_manager_maintenance_tasks, :project_secrets_manager_id, true
  end

  def down
    change_column_null :project_secrets_manager_maintenance_tasks, :project_secrets_manager_id, false
  end
end
