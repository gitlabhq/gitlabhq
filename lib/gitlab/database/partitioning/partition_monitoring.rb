# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class PartitionMonitoring
        def report_metrics_for_model(model)
          strategy = model.partitioning_strategy

          gauge_present.set({ table: model.table_name }, strategy.current_partitions.size)
          gauge_missing.set({ table: model.table_name }, strategy.missing_partitions.size)
          gauge_extra.set({ table: model.table_name }, strategy.extra_partitions.size)
        end

        private

        def gauge_present
          @gauge_present ||= Gitlab::Metrics.gauge(:db_partitions_present, 'Number of database partitions present')
        end

        def gauge_missing
          @gauge_missing ||= Gitlab::Metrics.gauge(:db_partitions_missing, 'Number of database partitions currently expected, but not present')
        end

        def gauge_extra
          @gauge_extra ||= Gitlab::Metrics.gauge(:db_partitions_extra, 'Number of database partitions currently attached to tables, but outside of their retention window and scheduled to be dropped')
        end
      end
    end
  end
end
