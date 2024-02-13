# frozen_string_literal: true

module ClickHouse
  class RebuildMaterializedViewService
    INSERT_BATCH_SIZE = 10_000_000

    VIEW_DEFINITION_QUERY = <<~SQL
      SELECT view_definition FROM information_schema.views
      WHERE table_name = {view_name:String} AND
      table_schema = {database_name:String}
    SQL

    def initialize(connection:, state: {})
      @connection = connection

      @view_name = state.fetch(:view_name)
      @tmp_view_name = state.fetch(:tmp_view_name)
      @view_table_name = state.fetch(:view_table_name)
      @tmp_view_table_name = state.fetch(:tmp_view_table_name)
      @source_table_name = state.fetch(:source_table_name)
    end

    def execute
      create_tmp_materialized_view_table
      create_tmp_materialized_view

      backfill_data

      rename_table
      drop_tmp_tables
    end

    private

    attr_reader :connection, :view_name, :tmp_view_name, :view_table_name, :tmp_view_table_name, :source_table_name

    def create_tmp_materialized_view_table
      # Create a tmp table from the existing table, use IF NOT EXISTS to avoid failure when the table exists.
      create_statement = show_create_table(view_table_name)
        .gsub("#{connection.database_name}.#{view_table_name}",
          "#{connection.database_name}.#{quote(tmp_view_table_name)}")
        .gsub('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS')

      connection.execute(create_statement)
    end

    def create_tmp_materialized_view
      # Create a tmp materialized view from the existing view, use IF NOT EXISTS to avoid failure when the view exists.
      create_statement = show_create_table(view_name)
        .gsub("#{connection.database_name}.#{view_name}",
          "#{connection.database_name}.#{quote(tmp_view_name)}")
        .gsub("#{connection.database_name}.#{view_table_name}",
          "#{connection.database_name}.#{quote(tmp_view_table_name)}")
        .gsub('CREATE MATERIALIZED VIEW', 'CREATE MATERIALIZED VIEW IF NOT EXISTS')

      connection.execute(create_statement)
    end

    def backfill_data
      # Take the query from the materialized view definition.
      query = ClickHouse::Client::Query.new(raw_query: VIEW_DEFINITION_QUERY, placeholders: {
        view_name: view_name,
        database_name: connection.database_name
      })
      view_query = connection.select(query).first['view_definition']

      iterator.each_batch(column: :id, of: INSERT_BATCH_SIZE) do |scope|
        # Use the materialized view query to backfill the new temporary table.
        # The materialized view query selects from the source table, example: FROM events.
        # Replace the FROM part and select data from a batched subquery.
        # Old: FROM events
        # New: FROM (SELECT .. FROM events WHERE id > x and id < y) events
        inner_query = "(#{scope.to_sql}) #{quote(source_table_name)}"

        query = view_query.gsub("FROM #{connection.database_name}.#{source_table_name}", "FROM #{inner_query}")

        # Insert the batch
        connection.execute("INSERT INTO #{quote(tmp_view_table_name)} #{query}")
      end
    end

    def rename_table
      # Swap the tables
      connection.execute("EXCHANGE TABLES #{quote(view_table_name)} AND #{quote(tmp_view_table_name)}")
    end

    def drop_tmp_tables
      connection.execute("DROP TABLE IF EXISTS #{quote(tmp_view_table_name)}")
      connection.execute("DROP TABLE IF EXISTS #{quote(tmp_view_name)}")
    end

    def show_create_table(table)
      result = connection.select("SHOW CREATE TABLE #{quote(table)}")

      raise "Table or view not found: #{table}" if result.empty?

      result.first['statement']
    end

    def quote(table)
      ApplicationRecord.connection.quote_table_name(table)
    end

    def iterator
      builder = ClickHouse::QueryBuilder.new(source_table_name)
      ClickHouse::Iterator.new(query_builder: builder, connection: connection)
    end
  end
end
