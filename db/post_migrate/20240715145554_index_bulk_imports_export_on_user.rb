# frozen_string_literal: true

class IndexBulkImportsExportOnUser < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.3'

  TABLE_NAME = :bulk_import_exports
  COLUMN_NAME = :user_id

  def up
    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: "index_#{TABLE_NAME}_on_#{COLUMN_NAME}"
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, name: "index_#{TABLE_NAME}_on_#{COLUMN_NAME}"
  end
end
