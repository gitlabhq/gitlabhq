# frozen_string_literal: true

class CreateAiUsageEventsTmpMv < ClickHouse::Migration
  def up
    # Captures writes landing in ai_usage_events while the copy migration runs. Overlap with the
    # copy is safe: both write the same canonical traversal_path, and the ReplacingMergeTree sort
    # key collapses the duplicates.
    execute <<~SQL
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
  end

  def down
    execute 'DROP VIEW IF EXISTS ai_usage_events_tmp_mv'
  end
end
