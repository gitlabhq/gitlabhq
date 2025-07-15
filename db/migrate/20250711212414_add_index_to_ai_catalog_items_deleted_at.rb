# frozen_string_literal: true

class AddIndexToAiCatalogItemsDeletedAt < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  INDEX_NAME = 'index_ai_catalog_items_where_deleted_at_is_null'

  def up
    add_concurrent_index :ai_catalog_items, :deleted_at, where: 'deleted_at IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_catalog_items, INDEX_NAME
  end
end
