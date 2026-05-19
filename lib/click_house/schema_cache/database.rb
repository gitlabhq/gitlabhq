# frozen_string_literal: true

module ClickHouse
  module SchemaCache
    class Database
      attr_reader :name

      def initialize(name:, tables: [])
        @name = name
        @tables_by_name = tables.index_by(&:name)
      end

      def tables
        @tables_by_name.values
      end

      def table_names
        @tables_by_name.keys
      end

      def table(table_name)
        @tables_by_name[table_name.to_s]
      end

      def table?(table_name)
        @tables_by_name.key?(table_name.to_s)
      end

      def columns(table_name)
        table(table_name)&.columns || []
      end

      def column(table_name, column_name)
        table(table_name)&.column(column_name)
      end
    end
  end
end
