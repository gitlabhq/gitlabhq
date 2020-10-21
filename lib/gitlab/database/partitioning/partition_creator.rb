# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class PartitionCreator
        def self.register(model)
          raise ArgumentError, "Only models with a #partitioning_strategy can be registered." unless model.respond_to?(:partitioning_strategy)

          models << model
        end

        def self.models
          @models ||= Set.new
        end

        LEASE_TIMEOUT = 1.minute
        LEASE_KEY = 'database_partition_creation_%s'

        attr_reader :models

        def initialize(models = self.class.models)
          @models = models
        end

        def create_partitions
          Gitlab::AppLogger.info("Checking state of dynamic postgres partitions")

          models.each do |model|
            # Double-checking before getting the lease:
            # The prevailing situation is no missing partitions
            next if missing_partitions(model).empty?

            only_with_exclusive_lease(model) do
              partitions_to_create = missing_partitions(model)

              next if partitions_to_create.empty?

              create(model, partitions_to_create)
            end
          rescue => e
            Gitlab::AppLogger.error("Failed to create partition(s) for #{model.table_name}: #{e.class}: #{e.message}")
          end
        end

        private

        def missing_partitions(model)
          return [] unless connection.table_exists?(model.table_name)

          model.partitioning_strategy.missing_partitions
        end

        def only_with_exclusive_lease(model)
          lease = Gitlab::ExclusiveLease.new(LEASE_KEY % model.table_name, timeout: LEASE_TIMEOUT)

          yield if lease.try_obtain
        ensure
          lease&.cancel
        end

        def create(model, partitions)
          connection.transaction do
            with_lock_retries do
              partitions.each do |partition|
                connection.execute partition.to_sql

                Gitlab::AppLogger.info("Created partition #{partition.partition_name} for table #{partition.table}")
              end
            end
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
