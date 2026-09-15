# frozen_string_literal: true

class AddNamespaceIdToBulkImportExportUploadUploadStates < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  TABLE_NAME = :bulk_import_export_upload_upload_states
  INDEX_NAME = :index_bulk_import_export_upload_upload_states_on_namespace_id

  def up
    add_column TABLE_NAME, :namespace_id, :bigint, if_not_exists: true

    add_concurrent_index TABLE_NAME, :namespace_id, name: INDEX_NAME
    add_concurrent_foreign_key TABLE_NAME, :namespaces, column: :namespace_id, on_delete: :cascade

    # Validating now is free: project_id is still NOT NULL, so every existing
    # row and every insert already has exactly one sharding key set.
    add_multi_column_not_null_constraint(TABLE_NAME, :project_id, :namespace_id)
  end

  def down
    remove_multi_column_not_null_constraint(TABLE_NAME, :project_id, :namespace_id)
    remove_foreign_key_if_exists TABLE_NAME, :namespaces, column: :namespace_id
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
    remove_column TABLE_NAME, :namespace_id, if_exists: true
  end
end
