# frozen_string_literal: true

class DropPublicColumnFromAiCatalogItems < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  INDEX_NAME = 'index_ai_catalog_items_on_public'

  def up
    remove_column :ai_catalog_items, :public
  end

  def down
    add_column :ai_catalog_items, :public, :boolean, default: false, null: false, if_not_exists: true

    add_concurrent_index :ai_catalog_items, :public, name: INDEX_NAME
  end
end
