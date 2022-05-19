# frozen_string_literal: true

class AddLastConsistencyCheckCursorsToVsaAggregations < Gitlab::Database::Migration[2.0]
  def up
    change_table(:analytics_cycle_analytics_aggregations, bulk: true) do |t|
      t.column :last_consistency_check_issues_stage_event_hash_id, :bigint, null: true
      t.column :last_consistency_check_issues_start_event_timestamp, :datetime_with_timezone, null: true
      t.column :last_consistency_check_issues_end_event_timestamp, :datetime_with_timezone, null: true
      t.column :last_consistency_check_issues_issuable_id, :bigint, null: true

      t.column :last_consistency_check_merge_requests_stage_event_hash_id, :bigint, null: true
      t.column :last_consistency_check_merge_requests_start_event_timestamp, :datetime_with_timezone, null: true
      t.column :last_consistency_check_merge_requests_end_event_timestamp, :datetime_with_timezone, null: true
      t.column :last_consistency_check_merge_requests_issuable_id, :bigint, null: true
    end
  end

  def down
    remove_column :analytics_cycle_analytics_aggregations, :last_consistency_check_issues_stage_event_hash_id
    remove_column :analytics_cycle_analytics_aggregations, :last_consistency_check_issues_start_event_timestamp
    remove_column :analytics_cycle_analytics_aggregations, :last_consistency_check_issues_end_event_timestamp
    remove_column :analytics_cycle_analytics_aggregations, :last_consistency_check_issues_issuable_id
    remove_column :analytics_cycle_analytics_aggregations, :last_consistency_check_merge_requests_stage_event_hash_id
    remove_column :analytics_cycle_analytics_aggregations, :last_consistency_check_merge_requests_start_event_timestamp
    remove_column :analytics_cycle_analytics_aggregations, :last_consistency_check_merge_requests_end_event_timestamp
    remove_column :analytics_cycle_analytics_aggregations, :last_consistency_check_merge_requests_issuable_id
  end
end
