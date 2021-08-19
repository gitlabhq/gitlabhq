# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class PartitionManager
        UnsafeToDetachPartitionError = Class.new(StandardError)

        def self.register(model)
          raise ArgumentError, "Only models with a #partitioning_strategy can be registered." unless model.respond_to?(:partitioning_strategy)

          models << model
        end

        def self.models
          @models ||= Set.new
        end

        LEASE_TIMEOUT = 1.minute
        MANAGEMENT_LEASE_KEY = 'database_partition_management_%s'
        RETAIN_DETACHED_PARTITIONS_FOR = 1.week

        attr_reader :models

        def initialize(models = self.class.models)
          @models = models
        end

        def sync_partitions
          Gitlab::AppLogger.info("Checking state of dynamic postgres partitions")

          models.each do |model|
            # Double-checking before getting the lease:
            # The prevailing situation is no missing partitions and no extra partitions
            next if missing_partitions(model).empty? && extra_partitions(model).empty?

            only_with_exclusive_lease(model, lease_key: MANAGEMENT_LEASE_KEY) do
              partitions_to_create = missing_partitions(model)
              create(partitions_to_create) unless partitions_to_create.empty?

              if Feature.enabled?(:partition_pruning, default_enabled: :yaml)
                partitions_to_detach = extra_partitions(model)
                detach(partitions_to_detach) unless partitions_to_detach.empty?
              end
            end
          rescue StandardError => e
            Gitlab::AppLogger.error(message: "Failed to create / detach partition(s)",
                                    table_name: model.table_name,
                                    exception_class: e.class,
                                    exception_message: e.message)
          end
        end

        private

        def missing_partitions(model)
          return [] unless connection.table_exists?(model.table_name)

          model.partitioning_strategy.missing_partitions
        end

        def extra_partitions(model)
          return [] unless connection.table_exists?(model.table_name)

          model.partitioning_strategy.extra_partitions
        end

        def only_with_exclusive_lease(model, lease_key:)
          lease = Gitlab::ExclusiveLease.new(lease_key % model.table_name, timeout: LEASE_TIMEOUT)

          yield if lease.try_obtain
        ensure
          lease&.cancel
        end

        def create(partitions)
          connection.transaction do
            with_lock_retries do
              partitions.each do |partition|
                connection.execute partition.to_sql

                Gitlab::AppLogger.info(message: "Created partition",
                                       partition_name: partition.partition_name,
                                       table_name: partition.table)
              end
            end
          end
        end

        def detach(partitions)
          connection.transaction do
            with_lock_retries do
              partitions.each { |p| detach_one_partition(p) }
            end
          end
        end

        def detach_one_partition(partition)
          assert_partition_detachable!(partition)

          connection.execute partition.to_detach_sql

          Postgresql::DetachedPartition.create!(table_name: partition.partition_name,
                                                drop_after: RETAIN_DETACHED_PARTITIONS_FOR.from_now)

          Gitlab::AppLogger.info(message: "Detached Partition",
                                 partition_name: partition.partition_name,
                                 table_name: partition.table)
        end

        def assert_partition_detachable!(partition)
          parent_table_identifier = "#{connection.current_schema}.#{partition.table}"

          if (example_fk = PostgresForeignKey.by_referenced_table_identifier(parent_table_identifier).first)
            raise UnsafeToDetachPartitionError, "Cannot detach #{partition.partition_name}, it would block while checking foreign key #{example_fk.name} on #{example_fk.constrained_table_identifier}"
          end
        end

        def with_lock_retries(&block)
          Gitlab::Database::WithLockRetries.new(
            klass: self.class,
            logger: Gitlab::AppLogger
          ).run(&block)
        end

        def connection
          ActiveRecord::Base.connection
        end
      end
    end
  end
end
