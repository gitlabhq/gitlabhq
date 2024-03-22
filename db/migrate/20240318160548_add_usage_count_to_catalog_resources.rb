# frozen_string_literal: true

class AddUsageCountToCatalogResources < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :catalog_resources, :last_30_day_usage_count, :integer, null: false, default: 0
    add_column :catalog_resources, :last_30_day_usage_count_updated_at, :datetime_with_timezone,
      null: false, default: '1970-01-01'
  end
end
