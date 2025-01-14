# frozen_string_literal: true

class AddBulkImportExportUploadsGroupIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :bulk_import_export_uploads, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :bulk_import_export_uploads, column: :group_id
    end
  end
end
