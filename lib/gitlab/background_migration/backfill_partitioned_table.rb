# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration to generically copy data from the given table into its corresponding partitioned table
    class BackfillPartitionedTable < BatchedMigrationJob
      operation_name :upsert_partitioned_table
      feature_category :database
      job_arguments :partitioned_table

      def perform
        validate_partition_table!

        bulk_copy = Gitlab::Database::PartitioningMigrationHelpers::BulkCopy.new(
          batch_table,
          partitioned_table,
          batch_column,
          connection: connection
        )

        each_sub_batch do |relation|
          bulk_copy.copy_relation(filter_sub_batch_content(relation))
        end
      end

      private

      def validate_partition_table!
        unless connection.table_exists?(partitioned_table)
          raise "exiting backfill migration because partitioned table '#{partitioned_table}' does not exist. " \
                "This could be due to rollback of the migration which created the partitioned table."
        end

        # rubocop: disable Style/GuardClause
        unless Gitlab::Database::PostgresPartitionedTable.find_by_name_in_current_schema(partitioned_table).present?
          raise "exiting backfill migration because the given destination table is not partitioned."
        end
        # rubocop: enable Style/GuardClause
      end

      def filter_sub_batch_content(relation)
        relation
      end
    end
  end
end
