# frozen_string_literal: true

class CreateAiCatalogItemConsumers < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    create_table :ai_catalog_item_consumers do |t|
      t.bigint :ai_catalog_item_id, index: true, null: false

      t.bigint :organization_id, index: true
      t.bigint :group_id, index: true
      t.bigint :project_id, index: true

      t.timestamps_with_timezone null: false

      t.boolean :enabled, default: false, null: false
      t.boolean :locked, default: true, null: false

      t.text :pinned_version_prefix, limit: 50
    end
  end
end
