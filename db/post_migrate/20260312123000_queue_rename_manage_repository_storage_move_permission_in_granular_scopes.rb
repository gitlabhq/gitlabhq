# frozen_string_literal: true

class QueueRenameManageRepositoryStorageMovePermissionInGranularScopes < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'RenameManageRepositoryStorageMovePermissionInGranularScopes'
  OLD_PERMISSION = 'manage_repository_storage_move'
  NEW_PERMISSION = 'create_repository_storage_move'

  def up
    queue_batched_background_migration(
      MIGRATION,
      :granular_scopes,
      :id,
      OLD_PERMISSION,
      NEW_PERMISSION
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :granular_scopes,
      :id,
      [OLD_PERMISSION, NEW_PERMISSION]
    )
  end
end
