# frozen_string_literal: true

class CreateAiUsageEventsTmpTable < ClickHouse::Migration
  def up
    # Identical to ai_usage_events except that traversal_path replaces namespace_path as the
    # leading sort key, so org-scoped `startsWith` lookups use the primary index. namespace_path
    # stays as a non-key column because materialized views still forward it to tables that have
    # not migrated yet.
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ai_usage_events_tmp
      (
        user_id UInt64,
        event UInt16,
        timestamp DateTime64(6, 'UTC'),
        namespace_path String DEFAULT '0/',
        traversal_path String DEFAULT '0/' CODEC(ZSTD(3)),
        extras String DEFAULT '{}'
      )
      ENGINE = ReplacingMergeTree
      PARTITION BY toYYYYMM(timestamp)
      ORDER BY (traversal_path, event, timestamp, user_id)
      SETTINGS index_granularity = 8192
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS ai_usage_events_tmp
    SQL
  end
end
