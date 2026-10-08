# frozen_string_literal: true

class FinalizeHkRenameWriteWorkItemPermissionInGranularScopes < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'RenameWriteWorkItemPermissionInGranularScopes',
      table_name: :granular_scopes,
      column_name: :id,
      job_arguments: ['write_work_item', %w[create_work_item update_work_item]],
      finalize: true
    )
  end

  def down; end
end
