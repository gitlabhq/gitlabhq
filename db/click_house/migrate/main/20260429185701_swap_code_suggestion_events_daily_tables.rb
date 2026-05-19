# frozen_string_literal: true

# Swaps code_suggestion_events_daily_new (which includes ide_name) with
# code_suggestion_events_daily, and updates the materialized views accordingly.
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/580851
class SwapCodeSuggestionEventsDailyTables < ClickHouse::Migration
  def up
    # Swap the underlying tables so that code_suggestion_events_daily becomes
    # the richer table (with ide_name) and code_suggestion_events_daily_new
    # becomes the legacy table.
    safe_table_swap('code_suggestion_events_daily', 'code_suggestion_events_daily_new', '_temp')

    # Update the materialized view that was writing to code_suggestion_events_daily
    # (now the new table after the swap) to also include ide_name.
    execute <<~SQL
      ALTER TABLE code_suggestion_events_daily_mv MODIFY QUERY
      SELECT
          namespace_path AS namespace_path,
          user_id AS user_id,
          toDate(timestamp) AS date,
          event AS event,
          toLowCardinality(JSONExtractString(extras, 'ide_name')) AS ide_name, # Only change
          toLowCardinality(JSONExtractString(extras, 'language')) AS language,
          JSONExtractUInt(extras, 'suggestion_size') AS suggestions_size_sum,
          1 AS occurrences
      FROM ai_usage_events
      WHERE event IN (1, 2, 3, 4, 5);
    SQL

    # Update the materialized view that was writing to code_suggestion_events_daily_new
    # (now the legacy table after the swap) to match the old schema (no ide_name).
    execute <<~SQL
      ALTER TABLE code_suggestion_events_daily_new_mv MODIFY QUERY
      SELECT
          namespace_path AS namespace_path,
          user_id AS user_id,
          toDate(timestamp) AS date,
          event AS event,
          toLowCardinality(JSONExtractString(extras, 'language')) AS language,
          JSONExtractUInt(extras, 'suggestion_size') AS suggestions_size_sum,
          1 AS occurrences
      FROM ai_usage_events
      WHERE event IN (1, 2, 3, 4, 5);
    SQL
  end

  def down
    # Reverse the table swap
    safe_table_swap('code_suggestion_events_daily', 'code_suggestion_events_daily_new', '_temp')

    # Restore code_suggestion_events_daily_mv to previous state (without IDE name)
    execute <<~SQL
      ALTER TABLE code_suggestion_events_daily_mv MODIFY QUERY
      SELECT
          namespace_path,
          user_id,
          toDate(timestamp) AS date,
          event,
          toLowCardinality(JSONExtractString(extras, 'language')) AS language,
          JSONExtractUInt(extras, 'suggestion_size') AS suggestions_size_sum,
          1 AS occurrences
      FROM ai_usage_events
      WHERE event IN (1, 2, 3, 4, 5);
    SQL

    # Restore code_suggestion_events_daily_new_mv to write to the new table (with ide_name)
    execute <<~SQL
      ALTER TABLE code_suggestion_events_daily_new_mv MODIFY QUERY
      SELECT
          namespace_path AS namespace_path,
          user_id AS user_id,
          toDate(timestamp) AS date,
          event AS event,
          toLowCardinality(JSONExtractString(extras, 'ide_name')) AS ide_name,
          toLowCardinality(JSONExtractString(extras, 'language')) AS language,
          JSONExtractUInt(extras, 'suggestion_size') AS suggestions_size_sum,
          1 AS occurrences
      FROM ai_usage_events
      WHERE event IN (1, 2, 3, 4, 5);
    SQL
  end
end
