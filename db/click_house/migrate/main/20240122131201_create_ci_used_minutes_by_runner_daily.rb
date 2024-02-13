# frozen_string_literal: true

class CreateCiUsedMinutesByRunnerDaily < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ci_used_minutes_by_runner_daily
      (
        --- GROUP BY/ORDER BY fields
        finished_at_bucket DateTime64(6, 'UTC') DEFAULT now64(),
        runner_type UInt8 DEFAULT 0,
        status LowCardinality(String) DEFAULT '',
        runner_id UInt64 DEFAULT 0,

        --- Aggregate fields
        count_builds AggregateFunction(count),
        total_duration SimpleAggregateFunction(sum, Int64)
      )
      ENGINE = AggregatingMergeTree()
      ORDER BY (finished_at_bucket, runner_type, status, runner_id)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS ci_used_minutes_by_runner_daily
    SQL
  end
end
