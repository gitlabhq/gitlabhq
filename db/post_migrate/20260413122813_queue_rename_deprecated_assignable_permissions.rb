# frozen_string_literal: true

class QueueRenameDeprecatedAssignablePermissions < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'RenameGranularScopePermission'

  def up
    queue_batched_background_migration(
      MIGRATION,
      :granular_scopes,
      :id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :granular_scopes, :id, [])
  end
end
