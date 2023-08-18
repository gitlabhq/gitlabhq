# frozen_string_literal: true

class CreateCatalogResourceComponents < Gitlab::Database::Migration[2.1]
  def up
    create_table :catalog_resource_components do |t|
      t.bigint :catalog_resource_id, null: false, index: true
      t.bigint :version_id, null: false, index: true
      t.bigint :project_id, null: false, index: true
      t.datetime_with_timezone :created_at, null: false
      t.integer :resource_type, default: 1, limit: 2, null: false
      t.jsonb :inputs, default: {}, null: false
      t.text :name, limit: 255, null: false
    end
  end

  def down
    drop_table :catalog_resource_components
  end
end
