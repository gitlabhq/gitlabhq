# frozen_string_literal: true

class AddGroupFkToImportExportUploads < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :import_export_uploads, :namespaces, column: :group_id, on_delete: :cascade
    add_concurrent_index :import_export_uploads, :group_id, unique: true, where: 'group_id IS NOT NULL'
  end

  def down
    remove_foreign_key_without_error(:import_export_uploads, column: :group_id)
    remove_concurrent_index(:import_export_uploads, :group_id)
  end
end
