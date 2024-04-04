# frozen_string_literal: true

module ClickHouse
  class Connection
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
