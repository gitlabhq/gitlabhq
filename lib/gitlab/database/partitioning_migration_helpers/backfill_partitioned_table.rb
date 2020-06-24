# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      # Class that will generically copy data from a given table into its corresponding partitioned table
      class BackfillPartitionedTable
        include ::Gitlab::Database::DynamicModelHelpers

        SUB_BATCH_SIZE = 2_500
        PAUSE_SECONDS = 0.25

        def perform(start_id, stop_id, source_table, partitioned_table, source_column)
          return unless Feature.enabled?(:backfill_partitioned_audit_events, default_enabled: true)

          if transaction_open?
            raise "Aborting job to backfill partitioned #{source_table} table! Do not run this job in a transaction block!"
          end

          unless table_exists?(partitioned_table)
            logger.warn "exiting backfill migration because partitioned table #{partitioned_table} does not exist. " \
              "This could be due to the migration being rolled back after migration jobs were enqueued in sidekiq"
            return
          end

          bulk_copy = BulkCopy.new(source_table, partitioned_table, source_column)
          parent_batch_relation = relation_scoped_to_range(source_table, source_column, start_id, stop_id)

          parent_batch_relation.each_batch(of: SUB_BATCH_SIZE) do |sub_batch|
            start_id, stop_id = sub_batch.pluck(Arel.sql("MIN(#{source_column}), MAX(#{source_column})")).first

            bulk_copy.copy_between(start_id, stop_id)
            sleep(PAUSE_SECONDS)
          end
        end

        private

        def connection
          ActiveRecord::Base.connection
        end

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
          define_batchable_model(source_table).where(source_key_column => start_id..stop_id)
        end

        # Helper class to copy data between two tables via upserts
        class BulkCopy
          DELIMITER = ', '

          attr_reader :source_table, :destination_table, :source_column

          def initialize(source_table, destination_table, source_column)
            @source_table = source_table
            @destination_table = destination_table
            @source_column = source_column
          end

          def copy_between(start_id, stop_id)
            connection.execute(<<~SQL)
              INSERT INTO #{destination_table} (#{column_listing})
              SELECT #{column_listing}
              FROM #{source_table}
              WHERE #{source_column} BETWEEN #{start_id} AND #{stop_id}
              FOR UPDATE
              ON CONFLICT (#{conflict_targets}) DO NOTHING
            SQL
          end

          private

          def connection
            @connection ||= ActiveRecord::Base.connection
          end

          def column_listing
            @column_listing ||= connection.columns(source_table).map(&:name).join(DELIMITER)
          end

          def conflict_targets
            connection.primary_key(destination_table).join(DELIMITER)
          end
        end
      end
    end
  end
end
