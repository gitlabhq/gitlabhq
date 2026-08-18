# frozen_string_literal: true

class CreateCatalogBundledResourceVersions < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  UNIQUE_INDEX_NAME = 'idx_catalog_bundled_versions_on_bundled_resource_and_semver'

  def up
    create_table :catalog_bundled_resource_versions, if_not_exists: true do |t|
      t.bigint :catalog_bundled_resource_id, null: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :released_at
      t.integer :semver_major, null: false
      t.integer :semver_minor, null: false
      t.integer :semver_patch, null: false
      t.boolean :semver_prefixed, null: false, default: false
      t.text :semver_prerelease, limit: 255
      # rubocop:disable Migration/AddLimitToTextColumns -- denormalized README content, mirrors catalog_resource_versions
      t.text :readme
      t.text :readme_html
      # rubocop:enable Migration/AddLimitToTextColumns

      t.index [:catalog_bundled_resource_id, :semver_major, :semver_minor, :semver_patch, :semver_prerelease],
        unique: true, nulls_not_distinct: true, name: UNIQUE_INDEX_NAME
    end

    add_concurrent_foreign_key :catalog_bundled_resource_versions, :catalog_bundled_resources,
      column: :catalog_bundled_resource_id, on_delete: :cascade
  end

  def down
    drop_table :catalog_bundled_resource_versions
  end
end
