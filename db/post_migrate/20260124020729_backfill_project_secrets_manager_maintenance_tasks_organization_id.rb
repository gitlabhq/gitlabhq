# frozen_string_literal: true

class BackfillProjectSecretsManagerMaintenanceTasksOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.9'

  TABLE_NAME = 'project_secrets_manager_maintenance_tasks'

  def up
    # Backfill organization_id from users table
    execute(<<~SQL)
      UPDATE #{TABLE_NAME}
      SET organization_id = users.organization_id
      FROM users
      WHERE #{TABLE_NAME}.user_id = users.id
        AND #{TABLE_NAME}.organization_id IS NULL
    SQL
  end

  def down
    # no-op - cannot rollback data changes
  end
end
