# frozen_string_literal: true

class AddDeprecatedToAiCatalogItemVersions < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :ai_catalog_item_versions, :deprecated, :boolean, default: false, null: false
  end
end
