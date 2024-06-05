# frozen_string_literal: true

class RecreateCodeSuggestionDailyUsageMv < ClickHouse::Migration
  def up
    execute <<~SQL
      DROP VIEW IF EXISTS code_suggestion_daily_usages_mv
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW code_suggestion_daily_usages_mv
      TO code_suggestion_daily_usages
      AS
      SELECT
        user_id,
        timestamp
      FROM code_suggestion_usages
      WHERE event IN (1, 2, 5)
      GROUP BY user_id, timestamp
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS code_suggestion_daily_usages_mv
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW code_suggestion_daily_usages_mv
      TO code_suggestion_daily_usages
      AS
      SELECT
        user_id,
        timestamp
      FROM code_suggestion_usages
      WHERE event = 1
      GROUP BY user_id, timestamp
    SQL
  end
end
