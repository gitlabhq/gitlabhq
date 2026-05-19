# frozen_string_literal: true

class QueueRenameWriteWorkItemPermissionInGranularScopes < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'RenameWriteWorkItemPermissionInGranularScopes'
  OLD_PERMISSION = 'write_work_item'
  NEW_PERMISSIONS = %w[create_work_item update_work_item]

  def up
    queue_batched_background_migration(
      MIGRATION,
      :granular_scopes,
      :id,
      OLD_PERMISSION,
      NEW_PERMISSIONS
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :granular_scopes,
      :id,
      [OLD_PERMISSION, NEW_PERMISSIONS]
    )
  end
end
