# frozen_string_literal: true

class RemoveInputsFromCatalogResourceComponents < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    remove_column :catalog_resource_components, :inputs
  end

  def down
    add_column :catalog_resource_components, :inputs, :jsonb, default: {}, null: false
  end
end
