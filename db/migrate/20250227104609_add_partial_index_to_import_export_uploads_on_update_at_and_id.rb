# frozen_string_literal: true

class AddPartialIndexToImportExportUploadsOnUpdateAtAndId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_import_export_uploads_updated_at_id_import_file'

  def up
    add_concurrent_index :import_export_uploads, [:updated_at, :id], where: 'import_file IS NOT NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :import_export_uploads, INDEX_NAME
  end
end
