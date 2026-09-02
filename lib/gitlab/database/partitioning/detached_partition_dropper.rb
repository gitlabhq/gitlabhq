# frozen_string_literal: true
module Gitlab
  module Database
    module Partitioning
      class DetachedPartitionDropper
        include ::Gitlab::Loggable

        PROCESSING_DELAY = 1.minute

        def perform
          Gitlab::AppLogger.info(
            build_structured_payload_labkit(message: 'Checking for previously detached partitions to drop')
          )

          Postgresql::DetachedPartition.ready_to_drop.find_each do |detached_partition|
            pg_partition = find_pg_partition(detached_partition.fully_qualified_table_name)

            if partition_attached?(pg_partition)
              unmark_partition(detached_partition)
            else
              finalize_detach(pg_partition) if pg_partition&.pending_detach
              drop_partition(detached_partition)
            end

            sleep(PROCESSING_DELAY)
          rescue StandardError => e
            Gitlab::AppLogger.error(
              build_structured_payload_labkit(
                message: 'Failed to drop previously detached partition',
                partition_name: detached_partition.table_name,
                exception_class: e.class,
                exception_message: e.message
              )
            )
          end
        end

        def drop_all_detached_partitions!
          raise 'This is meant to be used only for test cleanup' unless Rails.env.test?

          Postgresql::DetachedPartition.all.find_each do |detached_partition|
            pg_partition = find_pg_partition(detached_partition.fully_qualified_table_name)
            next if partition_attached?(pg_partition)

            finalize_detach(pg_partition) if pg_partition&.pending_detach
            drop_partition(detached_partition)
          end
        end

        private

        def unmark_partition(detached_partition)
          connection.transaction do
            # Another process may have already encountered this case and deleted this entry
            next unless try_lock_detached_partition(detached_partition.id)

            # The current partition was scheduled for deletion incorrectly
            # Dropping it now could delete in-use data and take locks that interrupt other database activity
            Gitlab::AppLogger.error(
              build_structured_payload_labkit(
                message: 'Prevented an attempt to drop an attached database partition',
                partition_name: detached_partition.table_name
              )
            )
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
          with_lock_retries(partition_name: detached_partition.table_name) do
            connection.transaction(requires_new: false) do
              next unless try_lock_detached_partition(detached_partition.id)

              # Another process may have already dropped this foreign key
              next unless PostgresForeignKey.by_constrained_table_identifier(partition_identifier).where(name: foreign_key.name).exists?

              connection.execute("ALTER TABLE #{connection.quote_table_name(partition_identifier)} DROP CONSTRAINT #{connection.quote_table_name(foreign_key.name)}")

              Gitlab::AppLogger.info(
                build_structured_payload_labkit(
                  message: 'Dropped foreign key for previously detached partition',
                  partition_name: detached_partition.table_name,
                  referenced_table_name: foreign_key.referenced_table_identifier,
                  foreign_key_name: foreign_key.name
                )
              )
            end
          end
        end

        def drop_detached_partition(detached_partition)
          connection.drop_table(detached_partition.fully_qualified_table_name, if_exists: true)

          Gitlab::AppLogger.info(
            build_structured_payload_labkit(
              message: 'Dropped previously detached partition',
              partition_name: detached_partition.table_name
            )
          )
        end

        # An interrupted DETACH ... CONCURRENTLY leaves the partition linked to its parent, so
        # dropping it from here would take ACCESS EXCLUSIVE on the parent. FINALIZE unlinks it
        # under SHARE UPDATE EXCLUSIVE instead, after which the drop takes no lock on the parent.
        def finalize_detach(pg_partition)
          with_lock_retries(partition_name: pg_partition.name) do
            connection.transaction(requires_new: false) do
              connection.execute(<<~SQL)
                ALTER TABLE #{connection.quote_table_name(pg_partition.parent_identifier)}
                DETACH PARTITION #{connection.quote_table_name(pg_partition.identifier)} FINALIZE
              SQL
            end
          end

          Gitlab::AppLogger.info(message: 'Finalized a pending partition detach',
            partition_name: pg_partition.name)
        end

        def find_pg_partition(partition_identifier)
          # PostgresPartition reads the pg_inherits view, so the partition is absent here once
          # it is fully detached, and present while it is attached or awaiting FINALIZE.
          Gitlab::Database::PostgresPartition.for_identifier(partition_identifier).first
        end

        def partition_attached?(pg_partition)
          pg_partition && !pg_partition.pending_detach
        end

        def try_lock_detached_partition(id)
          Postgresql::DetachedPartition.lock.find_by(id: id).present?
        end

        def connection
          Postgresql::DetachedPartition.connection
        end

        def with_lock_retries(partition_name:, &block)
          Gitlab::Database::Partitioning::WithPartitioningLockRetries.new(
            klass: self.class,
            logger: Gitlab::AppLogger,
            connection: connection,
            extra_log_params: { partition_name: partition_name }
          ).run(raise_on_exhaustion: true, &block)
        end
      end
    end
  end
end
