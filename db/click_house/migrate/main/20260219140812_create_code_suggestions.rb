# frozen_string_literal: true

class CreateCodeSuggestions < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ai_code_suggestions
      (
        `uid` String,
        `namespace_path` String,
        `user_id` UInt64,
        `timestamp` DateTime64(6, 'UTC'),
        `shown_at` AggregateFunction(minIf, Nullable(DateTime64(6, 'UTC')), UInt8),
        `accepted_at` AggregateFunction(maxIf, Nullable(DateTime64(6, 'UTC')), UInt8),
        `rejected_at` AggregateFunction(maxIf, Nullable(DateTime64(6, 'UTC')), UInt8),
        `language` String,
        `branch_name` String,
        `ide_name` String,
        `ide_vendor` String,
        `ide_version` String,
        `extension_name` String,
        `extension_version` String,
        `language_server_version` String,
        `model_name` String,
        `model_engine` String,
        `suggestion_size` SimpleAggregateFunction(max, UInt64),
        INDEX idx_ai_code_suggestions_timestamp timestamp TYPE minmax GRANULARITY 1
      ) ENGINE = AggregatingMergeTree
      PARTITION BY toYYYYMM(timestamp)
      ORDER BY (namespace_path, user_id, uid)
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS ai_code_suggestions_mv TO ai_code_suggestions
      AS SELECT
          JSONExtractString(extras, 'unique_tracking_id') AS uid,
          namespace_path,
          user_id,
          min(e.timestamp) AS timestamp,
          minIfState(toNullable(e.timestamp), e.event = 2) AS shown_at,
          maxIfState(toNullable(e.timestamp), e.event = 3) AS accepted_at,
          maxIfState(toNullable(e.timestamp), e.event = 4) AS rejected_at,
          any(JSONExtractString(e.extras, 'language')) AS language,
          any(JSONExtractString(e.extras, 'branch_name')) AS branch_name,
          any(JSONExtractString(e.extras, 'ide_name')) AS ide_name,
          any(JSONExtractString(e.extras, 'ide_vendor')) AS ide_vendor,
          any(JSONExtractString(e.extras, 'ide_version')) AS ide_version,
          any(JSONExtractString(e.extras, 'extension_name')) AS extension_name,
          any(JSONExtractString(e.extras, 'extension_version')) AS extension_version,
          any(JSONExtractString(e.extras, 'language_server_version')) AS language_server_version,
          any(JSONExtractString(e.extras, 'model_name')) AS model_name,
          any(JSONExtractString(e.extras, 'model_engine')) AS model_engine,
          max(JSONExtractUInt(e.extras, 'suggestion_size')) AS suggestion_size
      FROM ai_usage_events AS e
      WHERE e.event IN (2, 3, 4)
      GROUP BY
          uid,
          e.namespace_path,
          e.user_id
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS ai_code_suggestions_mv
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS ai_code_suggestions
    SQL
  end
end
