# frozen_string_literal: true

class RemoveUniqueIndexForImportExportUploadsOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  disable_ddl_transaction!

  INDEX_NAME = 'index_import_export_uploads_on_group_id'

  def up
    remove_concurrent_index_by_name :import_export_uploads, INDEX_NAME
  end

  def down
    add_concurrent_index :import_export_uploads, :group_id, unique: true, name: INDEX_NAME,
      where: 'group_id IS NOT NULL'
  end
end
