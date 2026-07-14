# frozen_string_literal: true

class AddVisibilityToAiCatalogItems < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :ai_catalog_items, :visibility, :smallint, default: 0, null: false
  end
end
