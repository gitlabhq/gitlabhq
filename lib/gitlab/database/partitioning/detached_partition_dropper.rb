# frozen_string_literal: true
module Gitlab
  module Database
    module Partitioning
      class DetachedPartitionDropper
        def perform
          return unless Feature.enabled?(:drop_detached_partitions, default_enabled: :yaml)

          Gitlab::AppLogger.info(message: "Checking for previously detached partitions to drop")

          Postgresql::DetachedPartition.ready_to_drop.find_each do |detached_partition|
            connection.transaction do
              # Another process may have already dropped the table and deleted this entry
              next unless (detached_partition = Postgresql::DetachedPartition.lock.find_by(id: detached_partition.id))

              drop_detached_partition(detached_partition.table_name)

              detached_partition.destroy!
            end
          rescue StandardError => e
            Gitlab::AppLogger.error(message: "Failed to drop previously detached partition",
                                    partition_name: detached_partition.table_name,
                                    exception_class: e.class,
                                    exception_message: e.message)
          end
        end

        private

        def drop_detached_partition(partition_name)
          partition_identifier = qualify_partition_name(partition_name)

          if partition_detached?(partition_identifier)
            connection.drop_table(partition_identifier, if_exists: true)

            Gitlab::AppLogger.info(message: "Dropped previously detached partition", partition_name: partition_name)
          else
            Gitlab::AppLogger.error(message: "Attempt to drop attached database partition", partition_name: partition_name)
          end
        end

        def qualify_partition_name(table_name)
          "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{table_name}"
        end

        def partition_detached?(partition_identifier)
          # PostgresPartition checks the pg_inherits view, so our partition will only show here if it's still attached
          # and thus should not be dropped
          !Gitlab::Database::PostgresPartition.for_identifier(partition_identifier).exists?
        end

        def connection
          Postgresql::DetachedPartition.connection
        end
      end
    end
  end
end
