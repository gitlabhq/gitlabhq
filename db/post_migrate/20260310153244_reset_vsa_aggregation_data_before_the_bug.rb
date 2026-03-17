# frozen_string_literal: true

class ResetVsaAggregationDataBeforeTheBug < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.com?

    restore_to_time = Date.parse('2026-02-27').to_time.utc.beginning_of_day
    define_batchable_model(:analytics_cycle_analytics_aggregations).each_batch(of: 1000) do |batch|
      # Reset the cursor for all aggregation tracker records before the bug was introduced
      condition = 'last_incremental_issues_updated_at >= ? OR last_incremental_merge_requests_updated_at >= ?'
      batch
        .where(condition, restore_to_time, restore_to_time)
        .update_all(
          last_incremental_merge_requests_id: 1,
          last_incremental_merge_requests_updated_at: restore_to_time,
          last_incremental_issues_id: 1,
          last_incremental_issues_updated_at: restore_to_time
        )
    end
  end

  def down
    # noop
  end
end
