# frozen_string_literal: true

module ClickHouse
  module SchemaCache
    class Loader
      MissingSchemaCacheError = Class.new(StandardError)

      def initialize(database:)
        @database = database
      end

      def load
        dir = ClickHouse::SchemaCache.schema_cache_path(@database)

        unless dir.directory?
          task_name = "gitlab:clickhouse:schema:dump:#{@database}"
          raise MissingSchemaCacheError,
            "ClickHouse schema cache not found at #{dir}. Run `#{task_name}` to generate it."
        end

        tables = Dir.glob(dir.join('*.yml')).map do |file|
          data = YAML.safe_load_file(file, permitted_classes: [Symbol]) || {}
          build_table(data)
        end

        Database.new(name: @database, tables: tables)
      end

      private

      def build_table(row)
        Table.new(
          name: row['name'],
          engine: row['engine'],
          engine_full: row['engine_full'],
          partition_key: row['partition_key'] || '',
          primary_key: row['primary_key'] || '',
          sorting_key: row['sorting_key'] || '',
          sampling_key: row['sampling_key'] || '',
          settings: row['settings'] || {},
          columns: (row['columns'] || []).each_with_index.map { |c, i| build_column(c, i + 1) }
        )
      end

      def build_column(row, position)
        Column.new(
          name: row['name'],
          type: row['type'],
          position: row.fetch('position', position),
          default_kind: row['default_kind'] || '',
          default_expression: row['default_expression'] || '',
          comment: row['comment'] || '',
          compression_codec: row['compression_codec'] || '',
          is_in_partition_key: row['is_in_partition_key'] || false,
          is_in_sorting_key: row['is_in_sorting_key'] || false,
          is_in_primary_key: row['is_in_primary_key'] || false,
          is_in_sampling_key: row['is_in_sampling_key'] || false
        )
      end
    end
  end
end
