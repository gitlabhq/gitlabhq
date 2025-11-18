# frozen_string_literal: true

class AddOfflineExportForeignKeyToBulkImportExports < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  TABLE_NAME = :bulk_import_exports
  COLUMN_NAME = :offline_export_id

  def up
    with_lock_retries do
      add_column TABLE_NAME, COLUMN_NAME, :bigint, if_not_exists: true
    end

    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: "index_#{TABLE_NAME}_on_#{COLUMN_NAME}"
    add_concurrent_foreign_key TABLE_NAME, :import_offline_exports, column: COLUMN_NAME, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_column TABLE_NAME, COLUMN_NAME, if_exists: true
    end
  end
end
