# frozen_string_literal: true

class AddPublicToAiCatalogItems < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :ai_catalog_items, :public, :boolean, default: false, null: false
  end
end
