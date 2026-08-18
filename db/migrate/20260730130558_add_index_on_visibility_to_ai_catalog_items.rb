# frozen_string_literal: true

class AddIndexOnVisibilityToAiCatalogItems < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ai_catalog_items_on_visibility_public_and_restricted'

  def up
    add_concurrent_index :ai_catalog_items, :visibility,
      name: INDEX_NAME, where: 'visibility IN (1, 2)'
  end

  def down
    remove_concurrent_index_by_name :ai_catalog_items, INDEX_NAME
  end
end
