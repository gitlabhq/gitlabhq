# frozen_string_literal: true

class AddSpecColumnToCatalogResourceComponents < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def change
    add_column :catalog_resource_components, :spec, :jsonb, default: {}, null: false
  end
end
