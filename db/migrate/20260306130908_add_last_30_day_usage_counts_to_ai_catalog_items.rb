# frozen_string_literal: true

class AddLast30DayUsageCountsToAiCatalogItems < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ai_catalog_items_on_last_30_day_usage_count_updated_at'

  def up
    add_column :ai_catalog_items, :last_30_day_usage_count, :integer, default: 0, null: false, if_not_exists: true
    add_column :ai_catalog_items, :last_30_day_usage_count_updated_at, :datetime_with_timezone,
      default: -> { "'1970-01-01 00:00:00+00'::timestamp" }, null: false, if_not_exists: true

    add_concurrent_index :ai_catalog_items, :last_30_day_usage_count_updated_at, name: INDEX_NAME, if_not_exists: true
  end

  def down
    remove_column :ai_catalog_items, :last_30_day_usage_count_updated_at, if_exists: true
    remove_column :ai_catalog_items, :last_30_day_usage_count, if_exists: true
  end
end
