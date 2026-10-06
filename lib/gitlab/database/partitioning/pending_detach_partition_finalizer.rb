# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class PendingDetachPartitionFinalizer
        include ::Gitlab::Loggable

        def perform
          Gitlab::AppLogger.info(
            build_structured_payload_labkit(message: 'Checking for pending detach partitions to finalize')
          )

          scheduled_identifiers = Postgresql::DetachedPartition.all.map(&:fully_qualified_table_name).to_set

          PostgresPartition.pending_detach.to_a.each do |pg_partition|
            # Finalizing leaves the partition fully detached, so without a scheduled drop nothing would remove it
            unless scheduled_identifiers.include?(pg_partition.identifier)
              Gitlab::AppLogger.warn(
                build_structured_payload_labkit(
                  message: 'Skipped finalizing a pending detach partition without a scheduled drop',
                  partition_name: pg_partition.name
                )
              )

              next
            end

            finalize(pg_partition)
          rescue StandardError => e
            Gitlab::AppLogger.error(
              build_structured_payload_labkit(
                message: 'Failed to finalize a pending detach partition',
                partition_name: pg_partition.name,
                exception_class: e.class,
                exception_message: e.message
              )
            )
          end
        end

        def finalize(pg_partition)
          lock_first = Feature.enabled?(:ci_finalize_pending_detach_partitions_daily, :instance)
          tables_to_lock = referenced_tables(pg_partition) if lock_first
          finalized = false

          with_lock_retries(partition_name: pg_partition.name) do
            connection.transaction(requires_new: false) do
              if lock_first
                lock_referenced_tables(tables_to_lock)
                lock_parent_table(pg_partition)

                # Another process may have finalized it while we waited for the locks
                next unless still_pending?(pg_partition)
              end

              execute(<<~SQL)
                ALTER TABLE #{connection.quote_table_name(pg_partition.parent_identifier)}
                DETACH PARTITION #{connection.quote_table_name(pg_partition.identifier)} FINALIZE
              SQL

              finalized = true
            end
          end

          return unless finalized

          Gitlab::AppLogger.info(message: 'Finalized a pending detach partition', partition_name: pg_partition.name)
        end

        private

        # FINALIZE takes SHARE ROW EXCLUSIVE on the tables the partition references, and writers take those
        # before the partition, so we take them first to wait for writers instead of deadlocking with them.
        def lock_referenced_tables(tables)
          return if tables.empty?

          quoted_tables = tables.map { |table| connection.quote_table_name(table) }.join(', ')
          execute("LOCK TABLE #{quoted_tables} IN SHARE ROW EXCLUSIVE MODE")
        end

        def referenced_tables(pg_partition)
          PostgresForeignKey
            .by_constrained_table_identifier(pg_partition.identifier)
            .distinct
            .pluck(:referenced_table_identifier)
            .sort
        end

        # FINALIZE takes this lock too, and it conflicts with itself, so a
        # second finalizer waits here until the first one has committed.
        def lock_parent_table(pg_partition)
          execute(
            "LOCK TABLE ONLY #{connection.quote_table_name(pg_partition.parent_identifier)} " \
              'IN SHARE UPDATE EXCLUSIVE MODE'
          )
        end

        def still_pending?(pg_partition)
          PostgresPartition.for_identifier(pg_partition.identifier).pending_detach.exists?
        end

        def with_lock_retries(partition_name:, &block)
          WithPartitioningLockRetries.new(
            klass: self.class,
            logger: Gitlab::AppLogger,
            connection: connection,
            extra_log_params: { partition_name: partition_name }
          ).run(raise_on_exhaustion: true, &block)
        end

        def execute(sql)
          connection.execute(sql) # rubocop:disable Database/AvoidUsingConnectionExecute -- DDL and locks run on the primary
        end

        def connection
          Postgresql::DetachedPartition.connection
        end
      end
    end
  end
end
