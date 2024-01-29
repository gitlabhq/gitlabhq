# frozen_string_literal: true

class CreateCiUsedMinutes < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ci_used_minutes
      (
        project_id UInt64 DEFAULT 0,
        status LowCardinality(String) DEFAULT '',
        runner_type UInt8 DEFAULT 0,
        finished_at_bucket DateTime64(6, 'UTC') DEFAULT now64(),

        count_builds AggregateFunction(count),
        total_duration SimpleAggregateFunction(sum, Int64)
      )
      ENGINE = AggregatingMergeTree()
      ORDER BY (finished_at_bucket, project_id, status, runner_type)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS ci_used_minutes
    SQL
  end
end
