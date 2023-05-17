# frozen_string_literal: true

class CreatePackagesNpmMetadataCaches < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  INDEX_NAME = 'index_npm_metadata_caches_on_package_name_project_id_unique'

  def up
    create_table :packages_npm_metadata_caches do |t|
      t.timestamps_with_timezone

      t.datetime_with_timezone :last_downloaded_at
      t.bigint :project_id, index: true
      t.integer :file_store, default: 1
      t.integer :size, null: false
      t.text :file, null: false, limit: 255
      t.text :package_name, null: false # rubocop:disable Migration/AddLimitToTextColumns

      t.index %i[package_name project_id], name: INDEX_NAME, unique: true, where: 'project_id IS NOT NULL'
    end
  end

  def down
    drop_table :packages_npm_metadata_caches
  end
end
