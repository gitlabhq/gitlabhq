# frozen_string_literal: true

class CreateAiCatalogItemVersionDependencies < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    create_table :ai_catalog_item_version_dependencies do |t|
      t.references(
        :ai_catalog_item_version,
        null: false,
        index: { name: 'index_ai_catalog_item_version_dependencies_on_item_version_id' }
      )
      t.references :dependency, null: false
      t.references :organization, null: false
    end
  end
end
