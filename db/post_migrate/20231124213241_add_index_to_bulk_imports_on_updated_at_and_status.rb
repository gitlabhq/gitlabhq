# frozen_string_literal: true

class AddIndexToBulkImportsOnUpdatedAtAndStatus < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_bulk_imports_on_updated_at_and_id_for_stale_status'

  def up
    add_concurrent_index :bulk_imports, [:updated_at, :id],
      where: 'STATUS in (0, 1)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :bulk_imports, name: INDEX_NAME
  end
end
