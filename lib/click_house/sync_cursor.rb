# frozen_string_literal: true

module ClickHouse
  class SyncCursor
    QUERY = <<~SQL
      SELECT argMax(primary_key_value, recorded_at) AS primary_key_value
      FROM sync_cursors
      WHERE table_name = {table_name:String}
      LIMIT 1
    SQL

    INSERT_CURSOR_QUERY = <<~SQL
      INSERT INTO sync_cursors
      (primary_key_value, table_name, recorded_at)
      VALUES ({primary_key_value:UInt64}, {table_name:String}, {recorded_at:DateTime64})
    SQL

    def self.cursor_for(identifier)
      query = ClickHouse::Client::Query.new(
        raw_query: QUERY,
        placeholders: { table_name: identifier.to_s }
      )

      # The query returns the default value (0) when no records are present.
      ClickHouse::Client.select(query, :main).first['primary_key_value']
    end

    def self.update_cursor_for(identifier, value)
      query = ClickHouse::Client::Query.new(
        raw_query: INSERT_CURSOR_QUERY,
        placeholders: {
          primary_key_value: value,
          table_name: identifier.to_s,
          recorded_at: Time.current.to_f
        }
      )

      ClickHouse::Client.execute(query, :main)
    end
  end
end
