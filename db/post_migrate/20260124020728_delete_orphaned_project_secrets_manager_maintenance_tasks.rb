# frozen_string_literal: true

class DeleteOrphanedProjectSecretsManagerMaintenanceTasks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.9'

  TABLE_NAME = 'project_secrets_manager_maintenance_tasks'

  def up
    # Delete rows where user_id references a non-existent user
    execute(<<~SQL)
      DELETE FROM #{TABLE_NAME}
      WHERE NOT EXISTS (
        SELECT 1 FROM users WHERE users.id = #{TABLE_NAME}.user_id
      )
    SQL
  end

  def down
    # no-op - data cleanup cannot be reversed
  end
end
