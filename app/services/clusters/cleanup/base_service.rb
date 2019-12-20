# frozen_string_literal: true

module Clusters
  module Cleanup
    class BaseService
      DEFAULT_EXECUTION_INTERVAL = 1.minute

      def initialize(cluster, execution_count = 0)
        @cluster = cluster
        @execution_count = execution_count
      end

      private

      attr_reader :cluster

      def logger
        @logger ||= Gitlab::Kubernetes::Logger.build
      end

      def log_event(event, extra_data = {})
        meta = {
          service: self.class.name,
          cluster_id: cluster.id,
          execution_count: @execution_count,
          event: event
        }

        logger.info(meta.merge(extra_data))
      end

      def schedule_next_execution(worker_class)
        log_event(:scheduling_execution, next_execution: @execution_count + 1)
        worker_class.perform_in(execution_interval, cluster.id, @execution_count + 1)
      end

      # Override this method to customize the execution interval
      def execution_interval
        DEFAULT_EXECUTION_INTERVAL
      end
    end
  end
end
