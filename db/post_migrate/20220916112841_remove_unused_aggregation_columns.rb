# frozen_string_literal: true

class RemoveUnusedAggregationColumns < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :analytics_cycle_analytics_aggregations, :last_full_run_processed_records
      remove_column :analytics_cycle_analytics_aggregations, :last_full_run_runtimes_in_seconds
      remove_column :analytics_cycle_analytics_aggregations, :last_full_run_issues_updated_at
      remove_column :analytics_cycle_analytics_aggregations, :last_full_run_mrs_updated_at
      remove_column :analytics_cycle_analytics_aggregations, :last_full_run_issues_id
      remove_column :analytics_cycle_analytics_aggregations, :last_full_run_merge_requests_id
    end
  end

  def down
    with_lock_retries do
      add_column(:analytics_cycle_analytics_aggregations,
                 :last_full_run_processed_records,
                 :integer,
                 array: true,
                 default: [],
                 null: false,
                 if_not_exists: true)
      add_column(:analytics_cycle_analytics_aggregations,
                 :last_full_run_runtimes_in_seconds,
                 :integer,
                 array: true,
                 default: [],
                 null: false,
                 if_not_exists: true)
      add_column(:analytics_cycle_analytics_aggregations,
                 :last_full_run_issues_updated_at,
                 :datetime_with_timezone,
                 if_not_exists: true)
      add_column(:analytics_cycle_analytics_aggregations,
                 :last_full_run_mrs_updated_at,
                 :datetime_with_timezone,
                 if_not_exists: true)
      add_column(:analytics_cycle_analytics_aggregations,
                 :last_full_run_issues_id,
                 :integer,
                 if_not_exists: true)
      add_column(:analytics_cycle_analytics_aggregations,
                 :last_full_run_merge_requests_id,
                 :integer,
                 if_not_exists: true)
    end

    add_check_constraint(:analytics_cycle_analytics_aggregations,
      'CARDINALITY(last_full_run_runtimes_in_seconds) <= 10',
      'chk_rails_7810292ec9')

    add_check_constraint(:analytics_cycle_analytics_aggregations,
      'CARDINALITY(last_full_run_processed_records) <= 10',
      'chk_rails_8b9e89687c')
  end
end
