# frozen_string_literal: true

class AddNotNullConstraintToPsmMaintenanceTasksProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    add_not_null_constraint :project_secrets_manager_maintenance_tasks, :project_id
    add_not_null_constraint :project_secrets_manager_maintenance_tasks, :root_namespace_id
    add_not_null_constraint :project_secrets_manager_maintenance_tasks, :parent_group_id
  end

  def down
    remove_not_null_constraint :project_secrets_manager_maintenance_tasks, :parent_group_id
    remove_not_null_constraint :project_secrets_manager_maintenance_tasks, :root_namespace_id
    remove_not_null_constraint :project_secrets_manager_maintenance_tasks, :project_id
  end
end
