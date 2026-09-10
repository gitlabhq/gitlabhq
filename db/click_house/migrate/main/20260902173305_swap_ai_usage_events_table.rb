# frozen_string_literal: true

class SwapAiUsageEventsTable < ClickHouse::Migration
  MV_DEFINITION = <<~SQL
    CREATE MATERIALIZED VIEW IF NOT EXISTS ai_usage_events_tmp_mv
    TO ai_usage_events_tmp
    AS
    SELECT
      user_id,
      event,
      timestamp,
      namespace_path,
      traversal_path,
      extras
    FROM ai_usage_events
  SQL

  def up
    safe_table_swap('ai_usage_events', 'ai_usage_events_tmp')

    # After the swap the view would mirror writes back into the old table, so it must go.
    # Materialized views reading FROM ai_usage_events resolve the name at insert time and so
    # follow the swap without changes.
    execute 'DROP VIEW IF EXISTS ai_usage_events_tmp_mv'
  end

  def down
    execute MV_DEFINITION

    safe_table_swap('ai_usage_events', 'ai_usage_events_tmp')
  end
end
