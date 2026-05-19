# frozen_string_literal: true

class FinalizeHkRenameManageRepositoryStorageMovePermissionInGranularSc < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'RenameManageRepositoryStorageMovePermissionInGranularScopes',
      table_name: :granular_scopes,
      column_name: :id,
      job_arguments: %w[manage_repository_storage_move create_repository_storage_move],
      finalize: true
    )
  end

  def down; end
end
