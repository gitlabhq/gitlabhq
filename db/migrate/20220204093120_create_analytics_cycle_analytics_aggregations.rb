# frozen_string_literal: true
class CreateAnalyticsCycleAnalyticsAggregations < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    create_table :analytics_cycle_analytics_aggregations, id: false do |t|
      t.references :group, index: false, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.integer :incremental_runtimes_in_seconds, array: true, default: [], null: false
      t.integer :incremental_processed_records, array: true, default: [], null: false
      t.integer :last_full_run_runtimes_in_seconds, array: true, default: [], null: false
      t.integer :last_full_run_processed_records, array: true, default: [], null: false
      t.integer :last_incremental_issues_id
      t.integer :last_incremental_merge_requests_id
      t.integer :last_full_run_issues_id
      t.integer :last_full_run_merge_requests_id

      t.datetime_with_timezone :last_incremental_run_at
      t.datetime_with_timezone :last_incremental_issues_updated_at
      t.datetime_with_timezone :last_incremental_merge_requests_updated_at
      t.datetime_with_timezone :last_full_run_at
      t.datetime_with_timezone :last_full_run_issues_updated_at
      t.datetime_with_timezone :last_full_run_mrs_updated_at
      t.datetime_with_timezone :last_consistency_check_updated_at

      t.boolean :enabled, default: true, null: false

      t.index :last_incremental_run_at, where: 'enabled IS TRUE', name: 'ca_aggregations_last_incremental_run_at', order: { last_incremental_run_at: 'ASC NULLS FIRST' }
      t.index :last_full_run_at, where: 'enabled IS TRUE', name: 'ca_aggregations_last_full_run_at', order: { last_full_run_at: 'ASC NULLS FIRST' }
      t.index :last_consistency_check_updated_at, where: 'enabled IS TRUE', name: 'ca_aggregations_last_consistency_check_updated_at', order: { last_consistency_check_updated_at: 'ASC NULLS FIRST' }

      t.check_constraint 'CARDINALITY(incremental_runtimes_in_seconds) <= 10'
      t.check_constraint 'CARDINALITY(incremental_processed_records) <= 10'
      t.check_constraint 'CARDINALITY(last_full_run_runtimes_in_seconds) <= 10'
      t.check_constraint 'CARDINALITY(last_full_run_processed_records) <= 10'
    end

    execute("ALTER TABLE analytics_cycle_analytics_aggregations ADD PRIMARY KEY (group_id)")
  end

  def down
    drop_table :analytics_cycle_analytics_aggregations
  end
end
