# frozen_string_literal: true
module Gitlab
  module Database
    module Partitioning
      class DetachedPartitionDropper
        def perform
          Gitlab::AppLogger.info(message: "Checking for previously detached partitions to drop")

          Postgresql::DetachedPartition.ready_to_drop.find_each do |detached_partition|
            if partition_attached?(detached_partition.fully_qualified_table_name)
              unmark_partition(detached_partition)
            else
              drop_partition(detached_partition)
            end
          rescue StandardError => e
            Gitlab::AppLogger.error(message: "Failed to drop previously detached partition",
              partition_name: detached_partition.table_name,
              exception_class: e.class,
              exception_message: e.message)
          end
        end

        private

        def unmark_partition(detached_partition)
          connection.transaction do
            # Another process may have already encountered this case and deleted this entry
            next unless try_lock_detached_partition(detached_partition.id)

            # The current partition was scheduled for deletion incorrectly
            # Dropping it now could delete in-use data and take locks that interrupt other database activity
            Gitlab::AppLogger.error(message: "Prevented an attempt to drop an attached database partition", partition_name: detached_partition.table_name)
            detached_partition.destroy!
          end
        end

        def drop_partition(detached_partition)
          remove_foreign_keys(detached_partition)

          connection.transaction do
            # Another process may have already dropped the table and deleted this entry
            next unless try_lock_detached_partition(detached_partition.id)

            drop_detached_partition(detached_partition)

            detached_partition.destroy!
          end
        end

        def remove_foreign_keys(detached_partition)
          partition_identifier = detached_partition.fully_qualified_table_name

          # We want to load all of these into memory at once to get a consistent view to loop over,
          # since we'll be deleting from this list as we go
          fks_to_drop = PostgresForeignKey.by_constrained_table_identifier(partition_identifier).to_a
          fks_to_drop.each do |foreign_key|
            drop_foreign_key_if_present(detached_partition, foreign_key)
          end
        end

        # Drops the given foreign key for the given detached partition, but only if another process has not already
        # detached the partition first. This method must be safe to call even if the associated partition table has already
        # been detached, as it could be called by multiple processes at once.
        def drop_foreign_key_if_present(detached_partition, foreign_key)
          # It is important to only drop one foreign key per transaction.
          # Dropping a foreign key takes an ACCESS EXCLUSIVE lock on both tables participating in the foreign key.

          partition_identifier = detached_partition.fully_qualified_table_name
          with_lock_retries do
            connection.transaction(requires_new: false) do
              next unless try_lock_detached_partition(detached_partition.id)

              # Another process may have already dropped this foreign key
              next unless PostgresForeignKey.by_constrained_table_identifier(partition_identifier).where(name: foreign_key.name).exists?

              connection.execute("ALTER TABLE #{connection.quote_table_name(partition_identifier)} DROP CONSTRAINT #{connection.quote_table_name(foreign_key.name)}")

              Gitlab::AppLogger.info(message: "Dropped foreign key for previously detached partition",
                partition_name: detached_partition.table_name,
                referenced_table_name: foreign_key.referenced_table_identifier,
                foreign_key_name: foreign_key.name)
            end
          end
        end

        def drop_detached_partition(detached_partition)
          connection.drop_table(detached_partition.fully_qualified_table_name, if_exists: true)

          Gitlab::AppLogger.info(message: "Dropped previously detached partition", partition_name: detached_partition.table_name)
        end

        def partition_attached?(partition_identifier)
          # PostgresPartition checks the pg_inherits view, so our partition will only show here if it's still attached
          # and thus should not be dropped
          Gitlab::Database::PostgresPartition.for_identifier(partition_identifier).exists?
        end

        def try_lock_detached_partition(id)
          Postgresql::DetachedPartition.lock.find_by(id: id).present?
        end

        def connection
          Postgresql::DetachedPartition.connection
        end

        def with_lock_retries(&block)
          Gitlab::Database::WithLockRetries.new(
            klass: self.class,
            logger: Gitlab::AppLogger,
            connection: connection
          ).run(raise_on_exhaustion: true, &block)
        end
      end
    end
  end
end
