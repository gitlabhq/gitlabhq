# frozen_string_literal: true

module Gitlab
  module Database
    class TablesSortedByForeignKeys
      include TSort

      def initialize(connection, tables)
        @connection = connection
        @tables = tables
      end

      def execute
        strongly_connected_components
      end

      private

      def tsort_each_node(&block)
        tables_dependencies.each_key(&block)
      end

      def tsort_each_child(node, &block)
        tables_dependencies[node].each(&block)
      end

      # it maps the tables to the tables that depend on it
      def tables_dependencies
        @tables.to_h do |table_name|
          [table_name, all_foreign_keys[table_name]&.map(&:from_table).to_a]
        end
      end

      def all_foreign_keys
        @all_foreign_keys ||= @tables.flat_map do |table_name|
          @connection.foreign_keys(table_name)
        end.group_by(&:to_table)
      end
    end
  end
end
