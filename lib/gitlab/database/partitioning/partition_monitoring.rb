# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class PartitionMonitoring
        attr_reader :models

        def initialize(models = PartitionManager.models)
          @models = models
        end

        def report_metrics
          models.each do |model|
            strategy = model.partitioning_strategy

            gauge_present.set({ table: model.table_name }, strategy.current_partitions.size)
            gauge_missing.set({ table: model.table_name }, strategy.missing_partitions.size)
          end
        end

        private

        def gauge_present
          @gauge_present ||= Gitlab::Metrics.gauge(:db_partitions_present, 'Number of database partitions present')
        end

        def gauge_missing
          @gauge_missing ||= Gitlab::Metrics.gauge(:db_partitions_missing, 'Number of database partitions currently expected, but not present')
        end
      end
    end
  end
end
