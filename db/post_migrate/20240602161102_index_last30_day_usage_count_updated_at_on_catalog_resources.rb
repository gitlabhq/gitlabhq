# frozen_string_literal: true

class IndexLast30DayUsageCountUpdatedAtOnCatalogResources < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_catalog_resources_on_last_30_day_usage_count_updated_at'

  def up
    add_concurrent_index :catalog_resources, :last_30_day_usage_count_updated_at, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :catalog_resources, INDEX_NAME
  end
end
