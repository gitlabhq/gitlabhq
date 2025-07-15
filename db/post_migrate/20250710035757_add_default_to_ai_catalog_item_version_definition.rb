# frozen_string_literal: true

class AddDefaultToAiCatalogItemVersionDefinition < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    change_column_default :ai_catalog_item_versions, :definition, from: nil, to: {}
  end
end
