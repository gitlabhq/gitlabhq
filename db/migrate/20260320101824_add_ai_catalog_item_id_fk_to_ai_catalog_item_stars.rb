# frozen_string_literal: true

class AddAiCatalogItemIdFkToAiCatalogItemStars < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.11'

  def up
    add_concurrent_foreign_key :ai_catalog_item_stars, :ai_catalog_items,
      column: :ai_catalog_item_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :ai_catalog_item_stars, :ai_catalog_items,
      column: :ai_catalog_item_id, on_delete: :cascade
  end
end
