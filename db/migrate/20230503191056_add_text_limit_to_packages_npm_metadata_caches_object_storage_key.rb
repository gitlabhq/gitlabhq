# frozen_string_literal: true

class AddTextLimitToPackagesNpmMetadataCachesObjectStorageKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :packages_npm_metadata_caches, :object_storage_key, 255
  end

  def down
    remove_text_limit :packages_npm_metadata_caches, :object_storage_key
  end
end
