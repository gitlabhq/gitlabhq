class MigrateRemainingMrMetricsPopulatingBackgroundMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'

    include ::EachBatch
  end

  def up
    Gitlab::BackgroundMigration.steal('PopulateMergeRequestMetricsWithEventsData')

    metrics_not_exists_clause =
      <<-SQL.strip_heredoc
        NOT EXISTS (SELECT 1 FROM merge_request_metrics
                    WHERE merge_request_metrics.merge_request_id = merge_requests.id)
    SQL

    MergeRequest.where(metrics_not_exists_clause).each_batch(of: BATCH_SIZE) do |relation, index|
      range = relation.pluck('MIN(id)', 'MAX(id)').first

      Gitlab::BackgroundMigration::PopulateMergeRequestMetricsWithEventsData
        .new
        .perform(*range)
    end
  end

  def down
  end
end
