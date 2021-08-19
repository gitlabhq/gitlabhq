# frozen_string_literal: true
module Gitlab
  module Database
    module Partitioning
      class DetachedPartitionDropper
        def perform
          return unless Feature.enabled?(:drop_detached_partitions, default_enabled: :yaml)

          Gitlab::AppLogger.info(message: "Checking for previously detached partitions to drop")
          Postgresql::DetachedPartition.ready_to_drop.find_each do |detached_partition|
            conn.transaction do
              # Another process may have already dropped the table and deleted this entry
              next unless (detached_partition = Postgresql::DetachedPartition.lock.find_by(id: detached_partition.id))

              unless check_partition_detached?(detached_partition)
                Gitlab::AppLogger.error(message: "Attempt to drop attached database partition", partition_name: detached_partition.table_name)
                detached_partition.destroy!
                next
              end

              drop_one(detached_partition)
            end
          rescue StandardError => e
            Gitlab::AppLogger.error(message: "Failed to drop previously detached partition",
                                    partition_name: detached_partition.table_name,
                                    exception_class: e.class,
                                    exception_message: e.message)
          end
        end

        private

        def drop_one(detached_partition)
          conn.transaction do
            conn.execute(<<~SQL)
              DROP TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{conn.quote_table_name(detached_partition.table_name)}
            SQL

            detached_partition.destroy!
          end
          Gitlab::AppLogger.info(message: "Dropped previously detached partition", partition_name: detached_partition.table_name)
        end

        def check_partition_detached?(detached_partition)
          # PostgresPartition checks the pg_inherits view, so our partition will only show here if it's still attached
          # and thus should not be dropped
          !PostgresPartition.for_identifier("#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{detached_partition.table_name}").exists?
        end

        def conn
          @conn ||= ApplicationRecord.connection
        end
      end
    end
  end
end
