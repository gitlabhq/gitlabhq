# frozen_string_literal: true

class AddPublishedByToCatalogResourceVersions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  INDEX_NAME = "index_catalog_resource_versions_on_published_by_id"

  def up
    add_column :catalog_resource_versions, :published_by_id, :bigint, if_not_exists: true

    add_concurrent_index :catalog_resource_versions, :published_by_id, name: INDEX_NAME

    add_concurrent_foreign_key :catalog_resource_versions, :users, column: :published_by_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :catalog_resource_versions, column: :published_by_id
    end

    remove_concurrent_index_by_name :catalog_resource_versions, name: INDEX_NAME

    remove_column :catalog_resource_versions, :published_by_id, :bigint, if_exists: true
  end
end
