# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class TableWithoutModel
        include PartitionedTable::ClassMethods

        attr_reader :table_name

        def initialize(table_name:, partitioned_column:, strategy:)
          @table_name = table_name
          partitioned_by(partitioned_column, strategy: strategy)
        end

        def connection
          Gitlab::Database::SharedModel.connection
        end
      end

      class << self
        def register_models(models)
          registered_models.merge(models)
        end

        def register_tables(tables)
          registered_tables.merge(tables)
        end

        def sync_partitions(models_to_sync = registered_for_sync)
          Gitlab::AppLogger.info(message: 'Syncing dynamic postgres partitions')

          Gitlab::Database::EachDatabase.each_model_connection(models_to_sync) do |model|
            PartitionManager.new(model).sync_partitions
          end

          Gitlab::AppLogger.info(message: 'Finished sync of dynamic postgres partitions')
        end

        def report_metrics(models_to_monitor = registered_models)
          partition_monitoring = PartitionMonitoring.new

          Gitlab::Database::EachDatabase.each_model_connection(models_to_monitor) do |model|
            partition_monitoring.report_metrics_for_model(model)
          end
        end

        def drop_detached_partitions
          Gitlab::AppLogger.info(message: 'Dropping detached postgres partitions')

          Gitlab::Database::EachDatabase.each_database_connection do
            DetachedPartitionDropper.new.perform
          end

          Gitlab::AppLogger.info(message: 'Finished dropping detached postgres partitions')
        end

        private

        def registered_models
          @registered_models ||= Set.new
        end

        def registered_tables
          @registered_tables ||= Set.new
        end

        def registered_for_sync
          registered_models + registered_tables.map do |table|
            TableWithoutModel.new(**table)
          end
        end
      end
    end
  end
end
