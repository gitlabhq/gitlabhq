# frozen_string_literal: true

class CreateAiCatalogItemVersion < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    create_table(:ai_catalog_item_versions, if_not_exists: true) do |t|
      t.datetime_with_timezone :release_date
      t.timestamps_with_timezone null: false
      t.bigint :organization_id, index: true, null: false
      t.bigint :ai_catalog_item_id, null: false
      t.integer :schema_version, limit: 2, null: false

      t.text :version, limit: 50, null: false
      t.jsonb :definition, null: false
    end

    add_index :ai_catalog_item_versions, [:ai_catalog_item_id, :version], unique: true,
      name: 'idx_ai_catalog_item_version_unique'
  end
end
