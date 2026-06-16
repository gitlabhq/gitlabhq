# frozen_string_literal: true

class RemoveNotNullFromGsmMaintenanceTasksUserId < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    change_column_null :group_secrets_manager_maintenance_tasks, :user_id, true
  end

  def down
    change_column_null :group_secrets_manager_maintenance_tasks, :user_id, false
  end
end
