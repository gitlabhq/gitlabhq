# frozen_string_literal: true

class AddIndexToBulkImportEntitiesOnBulkImportIdAndStatus < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_bulk_import_entities_on_bulk_import_id_and_status'
  OLD_INDEX_NAME = 'index_bulk_import_entities_on_bulk_import_id'

  def up
    add_concurrent_index :bulk_import_entities, [:bulk_import_id, :status], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :bulk_import_entities, name: OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :bulk_import_entities, :bulk_import_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :bulk_import_entities, name: NEW_INDEX_NAME
  end
end
