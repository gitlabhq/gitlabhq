# frozen_string_literal: true

module LooseForeignKeys
  class PartitionCleanerService < CleanerService
    def execute
      result = execute_partitioned_queries

      { affected_rows: result, table: loose_foreign_key_definition.from_table }
    end

    private

    def arel_table
      Arel::Table.new(@partition_identifier)
    end

    def primary_keys
      connection.primary_keys(@partition_identifier).map { |key| arel_table[key] }
    end

    def quoted_table_name
      Arel.sql(connection.quote_table_name(@partition_identifier))
    end

    def execute_partitioned_queries
      sum = 0

      Gitlab::Database::SharedModel.using_connection(connection) do
        target_table = loose_foreign_key_definition.from_table

        Gitlab::Database::PostgresPartitionedTable.each_partition(target_table) do |partition|
          @partition_identifier = partition.identifier

          result = connection.execute(build_query)
          sum += result.cmd_tuples
        end
      end

      sum
    end
  end
end
