# frozen_string_literal: true

class CreateAiCatalogItemStars < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    create_table :ai_catalog_item_stars do |t|
      t.timestamps_with_timezone null: false
      t.references :organization,
        foreign_key: { on_delete: :cascade },
        index: { name: 'idx_ai_catalog_item_stars_on_organization_id' },
        null: false
      t.bigint :ai_catalog_item_id, null: false
      t.bigint :user_id, null: false

      t.index [:ai_catalog_item_id, :user_id], unique: true,
        name: 'index_ai_catalog_item_stars_on_item_and_user'
      t.index :user_id
    end
  end
end
