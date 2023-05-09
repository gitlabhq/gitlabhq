# frozen_string_literal: true

class AddObjectStorageKeyToPackagesNpmMetadataCaches < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_npm_metadata_caches_on_object_storage_key'

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230503191056_add_text_limit_to_packages_npm_metadata_caches_object_storage_key
  def up
    unless column_exists?(:packages_npm_metadata_caches, :object_storage_key)
      # The existing table is empty.
      # rubocop:disable Rails/NotNullColumn
      add_column :packages_npm_metadata_caches, :object_storage_key, :text, null: false
      # rubocop:enable Rails/NotNullColumn
    end

    add_concurrent_index :packages_npm_metadata_caches, :object_storage_key, unique: true, name: INDEX_NAME
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :packages_npm_metadata_caches, :object_storage_key
  end
end
