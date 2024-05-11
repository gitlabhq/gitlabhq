# frozen_string_literal: true

class AddIndexCatalogResourcesOnUsageCount < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.0'

  INDEX_NAME = 'index_catalog_resources_on_last_30_day_usage_count'

  def up
    add_concurrent_index :catalog_resources, :last_30_day_usage_count, where: 'state = 1', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :catalog_resources, INDEX_NAME
  end
end
