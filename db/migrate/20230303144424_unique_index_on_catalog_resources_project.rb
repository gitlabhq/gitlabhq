# frozen_string_literal: true

class UniqueIndexOnCatalogResourcesProject < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_catalog_resources_on_project_id'

  def up
    remove_concurrent_index :catalog_resources, :project_id, name: INDEX_NAME
    add_concurrent_index :catalog_resources, :project_id, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :catalog_resources, :project_id, name: INDEX_NAME
    add_concurrent_index :catalog_resources, :project_id, name: INDEX_NAME
  end
end
