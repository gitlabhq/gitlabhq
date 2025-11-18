# frozen_string_literal: true

class BackfillCodeSuggestionEventsDailyNew < ClickHouse::Migration
  def up
    each_batch do |start_time, end_time|
      execute <<~SQL
        INSERT INTO code_suggestion_events_daily_new
        SELECT
            namespace_path,
            user_id,
            toDate(timestamp) as date,
            event,
            toLowCardinality(JSONExtractString(extras, 'ide_name')) AS ide_name,
            toLowCardinality(JSONExtractString(extras, 'language')) AS language,
            SUM(JSONExtractUInt(extras, 'suggestion_size')) AS suggestions_size_sum,
            COUNT(*) AS occurrences
        FROM ai_usage_events
        WHERE timestamp >= toDateTime64('#{start_time}', 6, 'UTC')
          AND timestamp <= toDateTime64('#{end_time}', 6, 'UTC')
          AND event IN (1, 2, 3, 4, 5)
        GROUP BY namespace_path, date, user_id, event, ide_name, language
      SQL
    end
  end

  def down
    execute <<-SQL
      TRUNCATE code_suggestion_events_daily_new
    SQL
  end

  def each_batch
    partitions =
      connection.select <<~SQL
        SELECT _partition_id AS month
        FROM ai_usage_events
        GROUP BY _partition_id
        ORDER BY _partition_id
      SQL

    partitions.each do |partition|
      partition_month = Date.strptime(partition['month'], '%Y%m')

      start_time = partition_month.beginning_of_month.to_time.utc.strftime('%Y-%m-%d 00:00:00')
      end_time = partition_month.end_of_month.to_time.utc.strftime('%Y-%m-%d 23:59:59')

      yield(start_time, end_time)
    end
  end
end
