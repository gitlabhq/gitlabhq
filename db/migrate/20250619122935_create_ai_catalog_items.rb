# frozen_string_literal: true

class CreateAiCatalogItems < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    create_table :ai_catalog_items do |t|
      t.bigint :organization_id, index: true, null: false
      t.bigint :project_id, index: true
      t.timestamps_with_timezone null: false
      t.integer :item_type, limit: 2, index: true, null: false

      t.text :description, null: false, limit: 1_024
      t.text :name, null: false, limit: 255
    end
  end
end
