# frozen_string_literal: true

class AddForeignKeyOnProjectImportExportRelationExportUploadUploadStatesV2 < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    add_concurrent_foreign_key :project_import_export_relation_export_upload_upload_states,
      :project_import_export_relation_export_upload_uploads,
      column: :project_import_export_relation_export_upload_upload_id,
      on_delete: :cascade,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :project_import_export_relation_export_upload_upload_states,
        column: :project_import_export_relation_export_upload_upload_id,
        reverse_lock_order: true
    end
  end
end
