# frozen_string_literal: true

class CreateCiFinishedBuildsAggregatedQueueingDelayPercentilesByOwner < ClickHouse::Migration
  TABLE_NAME = "ci_finished_builds_aggregated_queueing_delay_percentiles_by_owner"

  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS #{TABLE_NAME}
      (
        started_at_bucket DateTime64(6, 'UTC') DEFAULT now(),
        status LowCardinality(String) DEFAULT '',
        runner_type UInt8 DEFAULT 0,
        runner_owner_namespace_id UInt64 DEFAULT 0,

        count_builds AggregateFunction(count),
        queueing_duration_quantile AggregateFunction(quantile, Int64)
      )
      ENGINE = AggregatingMergeTree()
      ORDER BY (started_at_bucket, status, runner_type, runner_owner_namespace_id)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE #{TABLE_NAME}
    SQL
  end
end
