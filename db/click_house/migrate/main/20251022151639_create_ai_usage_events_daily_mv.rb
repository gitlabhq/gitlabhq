# frozen_string_literal: true

class CreateAiUsageEventsDailyMv < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS ai_usage_events_daily_mv TO ai_usage_events_daily
      AS SELECT
          namespace_path as namespace_path,
          toDate(timestamp) AS date,
          event as event,
          user_id as user_id,
          1 AS occurrences
      FROM ai_usage_events
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS ai_usage_events_daily_mv
    SQL
  end
end
