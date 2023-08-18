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
        @tables.index_with do |table_name|
          all_foreign_keys[table_name]
        end
      end

      def all_foreign_keys
        @all_foreign_keys ||= @tables.each_with_object(Hash.new { |h, k| h[k] = [] }) do |table, hash|
          foreign_keys_for(table).each do |fk|
            hash[fk.referenced_table_name] << table
          end
        end
      end

      def foreign_keys_for(table)
        # Detached partitions like gitlab_partitions_dynamic._test_gitlab_partition_20220101
        # store their foreign keys in the public schema.
        #
        # See spec/lib/gitlab/database/tables_sorted_by_foreign_keys_spec.rb
        # for an example
        table = ActiveRecord::ConnectionAdapters::PostgreSQL::Utils.extract_schema_qualified_name(table)

        Gitlab::Database::SharedModel.using_connection(@connection) do
          Gitlab::Database::PostgresForeignKey.by_constrained_table_name_or_identifier(table.identifier).load
        end
      end
    end
  end
end
