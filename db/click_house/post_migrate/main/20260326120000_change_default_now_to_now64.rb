# frozen_string_literal: true

class ChangeDefaultNowToNow64 < ClickHouse::Migration
  def up
    fetch_columns_with_default.each do |row|
      execute <<~SQL
        ALTER TABLE `#{row['table']}` MODIFY COLUMN `#{row['name']}` #{row['type']} DEFAULT now64(6, 'UTC')
      SQL
    end
  end

  def down
    # Skip rollback: we don't know if it was now64(), now() or now64(6)
  end

  private

  def fetch_columns_with_default
    # Anything starting with now: now64(), now(), now64(6)
    query = ClickHouse::Client::Query.new(
      raw_query: <<~SQL,
        SELECT table, name, type
        FROM system.columns
        WHERE database = {database:String}
          AND default_expression LIKE 'now%'
        ORDER BY table, name
      SQL
      placeholders: {
        database: connection.database_name
      }
    )

    connection.select(query)
  end
end
