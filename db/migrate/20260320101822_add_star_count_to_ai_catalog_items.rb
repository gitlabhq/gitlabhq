# frozen_string_literal: true

class AddStarCountToAiCatalogItems < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :ai_catalog_items, :star_count, :integer, default: 0, null: false, if_not_exists: true
  end
end
