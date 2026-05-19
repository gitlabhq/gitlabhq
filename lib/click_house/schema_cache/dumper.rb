# frozen_string_literal: true

module ClickHouse
  module SchemaCache
    class Dumper
      EXCLUDED_ENGINES = %w[View MaterializedView LiveView WindowView].freeze

      def initialize(connection:, database:)
        @connection = connection
        @database = database
      end

      def dump
        dir = ClickHouse::SchemaCache.schema_cache_path(@database)

        unless writable_target?(dir)
          puts "Directory #{dir} is not writeable, skipping schema cache dump" # rubocop:disable Rails/Output -- mirrors rake task output style
          return
        end

        FileUtils.mkdir_p(dir)

        written_files = tables.map do |table|
          path = ClickHouse::SchemaCache.table_cache_path(@database, table.name)
          File.atomic_write(path) { |f| f.write(YAML.dump(table.to_h)) }
          path.basename.to_s
        end

        prune_stale_files(dir, written_files)

        dir
      end

      def tables
        columns_by_table = fetch_columns
        fetch_tables.map do |row|
          Table.new(
            name: row['name'],
            engine: row['engine'],
            engine_full: row['engine_full'],
            partition_key: row['partition_key'],
            primary_key: row['primary_key'],
            sorting_key: row['sorting_key'],
            sampling_key: row['sampling_key'],
            settings: parse_settings(row['engine_full']),
            columns: columns_by_table.fetch(row['name'], [])
          )
        end
      end

      private

      def writable_target?(dir)
        return File.writable?(dir) if dir.exist?

        File.writable?(dir.dirname)
      end

      def prune_stale_files(dir, current_files)
        current = current_files.to_set
        Dir.glob(dir.join('*.yml')).each do |path|
          File.delete(path) unless current.include?(File.basename(path))
        end
      end

      def fetch_tables
        raw_query = <<~SQL
          SELECT name, engine, engine_full,
                 partition_key, primary_key, sorting_key, sampling_key
          FROM system.tables
          WHERE database = {database:String}
            AND engine NOT IN ({excluded_engines:Array(String)})
          ORDER BY name
        SQL

        query = ClickHouse::Client::Query.new(
          raw_query: raw_query,
          placeholders: { database: @connection.database_name, excluded_engines: EXCLUDED_ENGINES }
        )

        @connection.select(query)
      end

      def fetch_columns
        raw_query = <<~SQL
          SELECT table, name, type, position,
                 default_kind, default_expression, comment, compression_codec,
                 is_in_partition_key, is_in_sorting_key,
                 is_in_primary_key, is_in_sampling_key
          FROM system.columns
          WHERE database = {database:String}
          ORDER BY table, position
        SQL

        query = ClickHouse::Client::Query.new(
          raw_query: raw_query,
          placeholders: { database: @connection.database_name }
        )

        rows = @connection.select(query)
        rows.group_by { |row| row['table'] }.transform_values do |table_rows|
          table_rows.map { |row| build_column(row) }
        end
      end

      def build_column(row)
        Column.new(
          name: row['name'],
          type: row['type'],
          position: row['position'].to_i,
          default_kind: row['default_kind'],
          default_expression: row['default_expression'],
          comment: row['comment'],
          compression_codec: row['compression_codec'],
          is_in_partition_key: to_bool(row['is_in_partition_key']),
          is_in_sorting_key: to_bool(row['is_in_sorting_key']),
          is_in_primary_key: to_bool(row['is_in_primary_key']),
          is_in_sampling_key: to_bool(row['is_in_sampling_key'])
        )
      end

      def to_bool(value)
        value == 1 || value == true || value == '1'
      end

      def parse_settings(engine_full)
        return {} if engine_full.blank?

        match = engine_full.match(/\sSETTINGS\s+(.+)\z/)
        return {} unless match

        scan_settings(match[1])
      end

      def scan_settings(text)
        # parses settings like: `index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'`
        text.scan(/(\w+)\s*=\s*('(?:[^']|'')*'|\d+(?:\.\d+)?)/).to_h
      end
    end
  end
end
