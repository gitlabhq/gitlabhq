# frozen_string_literal: true

class AddPsmMaintenanceTasksOrgIdNotNull < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = 'project_secrets_manager_maintenance_tasks'

  def up
    # Add and validate NOT NULL constraint in a single statement
    add_not_null_constraint TABLE_NAME, :organization_id, validate: true
  end

  def down
    remove_not_null_constraint TABLE_NAME, :organization_id
  end
end
