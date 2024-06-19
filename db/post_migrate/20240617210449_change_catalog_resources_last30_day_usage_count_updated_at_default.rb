# frozen_string_literal: true

class ChangeCatalogResourcesLast30DayUsageCountUpdatedAtDefault < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    change_column_default :catalog_resources, :last_30_day_usage_count_updated_at, -> { 'NOW()' }
  end

  def down
    change_column_default :catalog_resources, :last_30_day_usage_count_updated_at, '1970-01-01'
  end
end
