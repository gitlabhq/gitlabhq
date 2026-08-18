# frozen_string_literal: true

class CreateCatalogBundledResourceComponents < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  UNIQUE_INDEX_NAME = 'idx_catalog_bundled_components_on_version_and_name'
  RESOURCE_INDEX_NAME = 'idx_catalog_bundled_components_on_bundled_resource_id'

  def up
    create_table :catalog_bundled_resource_components, if_not_exists: true do |t|
      t.bigint :catalog_bundled_resource_id, null: false
      t.bigint :catalog_bundled_version_id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.text :name, null: false, limit: 255
      t.jsonb :spec, null: false, default: {}

      t.index [:catalog_bundled_version_id, :name], unique: true, name: UNIQUE_INDEX_NAME
      t.index :catalog_bundled_resource_id, name: RESOURCE_INDEX_NAME
    end

    add_concurrent_foreign_key :catalog_bundled_resource_components, :catalog_bundled_resource_versions,
      column: :catalog_bundled_version_id, on_delete: :cascade
  end

  def down
    drop_table :catalog_bundled_resource_components
  end
end
