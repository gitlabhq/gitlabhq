# frozen_string_literal: true

module ClickHouse
  class Connection
    include Gitlab::Utils::StrongMemoize

    def initialize(database, configuration = ClickHouse::Client.configuration)
      @database = database
      @configuration = configuration
    end

    def select(query)
      ClickHouse::Client.select(query, database, configuration)
    end

    def execute(query)
      ClickHouse::Client.execute(query, database, configuration)
    end

    def insert_csv(query, file)
      ClickHouse::Client.insert_csv(query, file, database, configuration)
    end

    def ping
      execute('SELECT 1')
    end

    def database_name
      configuration.databases[database]&.database
    end

    def database_engine
      raw_query = <<~SQL
        SELECT engine
        FROM system.databases WHERE name = {database_name: String}
        LIMIT 1
      SQL

      placeholders = { database_name: database_name }

      query = ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders)

      # Falling back to 'Atomic' engine if we cannot determine the DB engine.
      # This fallback will likely never happen as the application wouldn't be
      # able to boot up without an existing database.
      select(query).first['engine'] || 'Atomic'
    end
    strong_memoize_attr :database_engine

    def replicated_engine?
      database_engine == 'Replicated'
    end

    def table_exists?(table_name)
      raw_query = <<~SQL.squish
        SELECT 1 FROM system.tables
        WHERE name = {table_name: String} AND database = {database_name: String}
      SQL

      placeholders = { table_name: table_name, database_name: database_name }

      query = ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders)

      select(query).any?
    end

    private

    attr_reader :database, :configuration
  end
end
