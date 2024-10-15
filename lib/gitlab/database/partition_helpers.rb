# frozen_string_literal: true

module Gitlab
  module Database
    module PartitionHelpers
      def partition?(table_name)
        if view_exists?(:postgres_partitions)
          Gitlab::Database::PostgresPartition.partition_exists?(table_name)
        else
          Gitlab::Database::PostgresPartition.legacy_partition_exists?(table_name)
        end
      end

      def table_partitioned?(table_name)
        Gitlab::Database::PostgresPartitionedTable
          .find_by_name_in_current_schema(table_name)
          .present?
      end
    end
  end
end
