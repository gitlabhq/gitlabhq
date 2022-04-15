# frozen_string_literal: true

class AddRuntimeDataColumnsToVsaAggregations < Gitlab::Database::Migration[1.0]
  def up
    change_table(:analytics_cycle_analytics_aggregations, bulk: true) do |t|
      t.integer :full_runtimes_in_seconds, array: true, default: [], null: false
      t.integer :full_processed_records, array: true, default: [], null: false
      t.column :last_full_merge_requests_updated_at, :datetime_with_timezone
      t.column :last_full_issues_updated_at, :datetime_with_timezone
      t.integer :last_full_issues_id
      t.integer :last_full_merge_requests_id
    end
  end

  def down
    remove_column :analytics_cycle_analytics_aggregations, :full_runtimes_in_seconds
    remove_column :analytics_cycle_analytics_aggregations, :full_processed_records
    remove_column :analytics_cycle_analytics_aggregations, :last_full_merge_requests_updated_at
    remove_column :analytics_cycle_analytics_aggregations, :last_full_issues_updated_at
    remove_column :analytics_cycle_analytics_aggregations, :last_full_issues_id
    remove_column :analytics_cycle_analytics_aggregations, :last_full_merge_requests_id
  end
end
