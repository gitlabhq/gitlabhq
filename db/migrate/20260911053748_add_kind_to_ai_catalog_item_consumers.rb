# frozen_string_literal: true

class AddKindToAiCatalogItemConsumers < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def up
    add_column :ai_catalog_item_consumers, :kind, :smallint, default: 0, null: false, if_not_exists: true
  end

  def down
    remove_column :ai_catalog_item_consumers, :kind, if_exists: true
  end
end
