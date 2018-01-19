# frozen_string_literal: true
# rubocop:disable GitlabSecurity/SqlInjection

class SchedulePopulateMergeRequestMetricsWithEventsData < ActiveRecord::Migration
  DOWNTIME = false
  BATCH_SIZE = 10_000
  MIGRATION = 'PopulateMergeRequestMetricsWithEventsData'

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'

    include ::EachBatch
  end

  def up
    say 'Scheduling `PopulateMergeRequestMetricsWithEventsData` jobs'
    # It will update around 4_000_000 records in batches of 10_000 merge
    # requests (running between 10 minutes) and should take around 66 hours to complete.
    # Apparently, production PostgreSQL is able to vacuum 10k-20k dead_tuples by
    # minute, and at maximum, each of these jobs should UPDATE 20k records.
    #
    # More information about the updates in `PopulateMergeRequestMetricsWithEventsData` class.
    #
    MergeRequest.all.each_batch(of: BATCH_SIZE) do |relation, index|
      range = relation.pluck('MIN(id)', 'MAX(id)').first

      BackgroundMigrationWorker.perform_in(index * 10.minutes, MIGRATION, range)
    end
  end

  def down
    execute "update merge_request_metrics set latest_closed_at = null"
    execute "update merge_request_metrics set latest_closed_by_id = null"
    execute "update merge_request_metrics set merged_by_id = null"
  end
end
