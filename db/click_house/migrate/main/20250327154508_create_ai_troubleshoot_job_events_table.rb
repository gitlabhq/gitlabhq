# frozen_string_literal: true

class CreateAiTroubleshootJobEventsTable < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS troubleshoot_job_events
      (
        user_id UInt64 NOT NULL DEFAULT 0,
        timestamp DateTime64(6, 'UTC') NOT NULL DEFAULT now64(),
        job_id UInt64 NOT NULL DEFAULT 0,
        project_id UInt64 NOT NULL DEFAULT 0,
        event UInt8 NOT NULL DEFAULT 0,
        namespace_path String DEFAULT '',
        pipeline_id UInt64 DEFAULT 0,
        merge_request_id UInt64 DEFAULT 0
      )
      ENGINE = ReplacingMergeTree
      PARTITION BY toYear(timestamp)
      ORDER BY (user_id, event, timestamp)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS troubleshoot_job_events
    SQL
  end
end
