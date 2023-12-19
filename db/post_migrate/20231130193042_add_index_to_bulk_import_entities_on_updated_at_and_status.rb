# frozen_string_literal: true

class AddIndexToBulkImportEntitiesOnUpdatedAtAndStatus < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_bulk_import_entities_for_stale_status'

  def up
    add_concurrent_index :bulk_import_entities, [:updated_at, :id],
      where: 'status in (0, 1)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :bulk_import_entities, name: INDEX_NAME
  end
end
