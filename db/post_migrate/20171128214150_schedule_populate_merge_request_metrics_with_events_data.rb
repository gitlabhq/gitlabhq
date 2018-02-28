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
    merge_requests = MergeRequest.where("id IN (#{updatable_merge_requests_union_sql})").reorder(:id)

    say 'Scheduling `PopulateMergeRequestMetricsWithEventsData` jobs'
    # It will update around 4_000_000 records in batches of 10_000 merge
    # requests (running between 10 minutes) and should take around 66 hours to complete.
    # Apparently, production PostgreSQL is able to vacuum 10k-20k dead_tuples by
    # minute, and at maximum, each of these jobs should UPDATE 20k records.
    #
    # More information about the updates in `PopulateMergeRequestMetricsWithEventsData` class.
    #
    merge_requests.each_batch(of: BATCH_SIZE) do |relation, index|
      range = relation.pluck('MIN(id)', 'MAX(id)').first

      BackgroundMigrationWorker.perform_in(index * 10.minutes, MIGRATION, range)
    end
  end

  def down
    execute "update merge_request_metrics set latest_closed_at = null"
    execute "update merge_request_metrics set latest_closed_by_id = null"
    execute "update merge_request_metrics set merged_by_id = null"
  end

  private

  # On staging:
  # Planning time: 0.682 ms
  # Execution time: 22033.158 ms
  #
  def updatable_merge_requests_union_sql
    metrics_not_exists_clause =
      'NOT EXISTS (SELECT 1 FROM merge_request_metrics WHERE merge_request_metrics.merge_request_id = merge_requests.id)'

    without_metrics_data = <<-SQL.strip_heredoc
      merge_request_metrics.merged_by_id IS NULL OR
      merge_request_metrics.latest_closed_by_id IS NULL OR
      merge_request_metrics.latest_closed_at IS NULL
    SQL

    mrs_without_metrics_record = MergeRequest
      .where(metrics_not_exists_clause)
      .select(:id)

    mrs_without_events_data = MergeRequest
      .joins('INNER JOIN merge_request_metrics ON merge_requests.id = merge_request_metrics.merge_request_id')
      .where(without_metrics_data)
      .select(:id)

    Gitlab::SQL::Union.new([mrs_without_metrics_record, mrs_without_events_data]).to_sql
  end
end
