# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      # Class that will generically copy data from a given table into its corresponding partitioned table
      class BackfillPartitionedTable < ::Gitlab::BackgroundMigration::BaseJob
        include ::Gitlab::Database::DynamicModelHelpers

        SUB_BATCH_SIZE = 2_500
        PAUSE_SECONDS = 0.25

        def perform(start_id, stop_id, source_table, partitioned_table, source_column)
          if transaction_open?
            raise "Aborting job to backfill partitioned #{source_table} table! Do not run this job in a transaction block!"
          end

          unless table_exists?(partitioned_table)
            logger.warn "exiting backfill migration because partitioned table '#{partitioned_table}' does not exist. " \
              "This could be due to the migration being rolled back after migration jobs were enqueued in sidekiq"
            return
          end

          bulk_copy = Gitlab::Database::PartitioningMigrationHelpers::BulkCopy.new(source_table, partitioned_table, source_column, connection: connection)
          parent_batch_relation = relation_scoped_to_range(source_table, source_column, start_id, stop_id)

          parent_batch_relation.each_batch(of: SUB_BATCH_SIZE) do |sub_batch|
            sub_start_id, sub_stop_id = sub_batch.pick(Arel.sql("MIN(#{source_column}), MAX(#{source_column})"))

            bulk_copy.copy_between(sub_start_id, sub_stop_id)
            sleep(PAUSE_SECONDS)
          end

          mark_jobs_as_succeeded(start_id, stop_id, source_table, partitioned_table, source_column)
        end

        private

        def transaction_open?
          connection.transaction_open?
        end

        def table_exists?(table)
          connection.table_exists?(table)
        end

        def logger
          @logger ||= ::Gitlab::BackgroundMigration::Logger.build
        end

        def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
          define_batchable_model(source_table, connection: connection)
            .where(source_key_column => start_id..stop_id)
        end

        def mark_jobs_as_succeeded(*arguments)
          BackgroundMigrationJob.mark_all_as_succeeded(self.class.name, arguments)
        end
      end
    end
  end
end
