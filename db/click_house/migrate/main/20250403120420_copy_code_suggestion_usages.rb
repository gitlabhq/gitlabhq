# frozen_string_literal: true

class CopyCodeSuggestionUsages < ClickHouse::Migration
  def up
    execute <<~SQL
      INSERT INTO code_suggestion_events
      (
          user_id,
          event,
          timestamp,
          namespace_path,
          unique_tracking_id,
          language,
          suggestion_size,
          branch_name
      )
      SELECT
          user_id,
          event,
          CASE WHEN r5 = r3 THEN r3 ELSE floor(toFloat64(orig_timestamp), 3) END as timestamp,
          namespace_path,
          unique_tracking_id,
          language,
          suggestion_size,
          branch_name
      FROM
        (SELECT user_id, event,
                      round(toFloat64(timestamp),5) as r5,
                      round(toFloat64(timestamp),3) as r3,
                      timestamp as orig_timestamp,
                      namespace_path, unique_tracking_id, language, suggestion_size, branch_name
               FROM code_suggestion_usages)
    SQL
  end

  def down
    # no-op
  end
end
