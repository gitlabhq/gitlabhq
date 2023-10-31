# frozen_string_literal: true

class AddIndexToCatalogResourcesOnState < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  disable_ddl_transaction!

  INDEX_NAME = 'index_catalog_resources_on_state'

  def up
    add_concurrent_index :catalog_resources, :state, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :catalog_resources, INDEX_NAME
  end
end
