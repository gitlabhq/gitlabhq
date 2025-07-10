# frozen_string_literal: true

class AddIndexToAiCatalogItemsPublic < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  INDEX_NAME = 'index_ai_catalog_items_on_public'

  def up
    add_concurrent_index :ai_catalog_items, :public, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_catalog_items, INDEX_NAME
  end
end
