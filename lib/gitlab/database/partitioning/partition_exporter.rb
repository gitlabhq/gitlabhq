# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      # Export integer and date range partition definitions for a given connection
      # so they can be imported into another cell prior to PG replication,
      # to avoid insertion errors.
      class PartitionExporter
        include PartitionKeyColumnTypes

        SUPPORTED_PARTITION_TYPES = Set.new(INTEGER_TYPES + DATE_TYPES).freeze

        # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
        def initialize(connection:)
          @connection = connection
        end

        # @return [Array<Hash>]
        #   Array of { table_name: String, partition_type: String, partitions: Array<Hash> } where
        #   integer partition hashes are { partition_name: String, from: Integer, to: Integer } and
        #   date partition hashes are { partition_name: String, from: String|nil, to: String }.
        def export
          results = []

          Gitlab::Database::SharedModel.using_connection(@connection) do
            tables = Gitlab::Database::PostgresPartitionedTable.where(strategy: 'range').where.not(key_columns: [])
            key_types = partition_key_types(tables)

            tables.each do |table|
              partition_type = key_types[table.identifier]
              next unless SUPPORTED_PARTITION_TYPES.include?(partition_type)

              partitions = export_partitions_for_type(table, partition_type)
              results << { table_name: table.name, partition_type: partition_type, partitions: partitions }
            end
          end

          results.sort_by { |result| result[:table_name] }
        end

        private

        def partition_key_types(tables)
          pairs = tables.map { |table| [table.key_columns.first, table.identifier] }

          return {} if pairs.empty?

          values = pairs.map { |col, id| "(#{@connection.quote(col)}, #{@connection.quote(id)})" }.join(', ')

          @connection.select_rows(<<~SQL).to_h
            SELECT refs.identifier, format_type(a.atttypid, a.atttypmod)
            FROM (VALUES #{values}) AS refs(key_column, identifier)
            JOIN pg_attribute a
              ON a.attrelid = refs.identifier::regclass
             AND a.attname = refs.key_column
             AND a.attnum > 0
          SQL
        end

        def export_partitions_for_type(table, partition_type)
          if INTEGER_TYPES.include?(partition_type)
            export_partitions_for(table, IntRangePartition)
          elsif DATE_TYPES.include?(partition_type)
            export_partitions_for(table, TimePartition)
          end
        end

        def export_partitions_for(table, partition_class)
          table.postgres_partitions.filter_map do |partition|
            parsed_partition = partition_class.from_sql(table.name, partition.name, partition.condition)
            parsed_partition.export_definition
          rescue ArgumentError, NotImplementedError
            nil
          end
        end
      end
    end
  end
end
