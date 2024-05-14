# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module MetricsHelper
      include ::Gitlab::SidekiqMiddleware::WorkerContext

      TRUE_LABEL = "yes"
      FALSE_LABEL = "no"

      private

      def create_labels(worker_class, queue, job)
        worker = find_worker(worker_class, job)

        # This should never happen: we should always be able to find a
        # worker class for a given Sidekiq job. But if we can't, we
        # shouldn't blow up here, because we want to record this in our
        # metrics.
        worker_name = worker.try(:name) || worker.class.name

        labels = { queue: queue.to_s, # rubocop:disable Cop/RedisQueueUsage -- assigning a constant is acceptable
                   worker: worker_name,
                   urgency: "",
                   external_dependencies: FALSE_LABEL,
                   feature_category: "",
                   boundary: "",
                   destination_shard_redis: Gitlab::Redis::Queues::SIDEKIQ_MAIN_SHARD_INSTANCE_NAME }

        return labels unless worker.respond_to?(:get_urgency)

        labels[:urgency] = worker.get_urgency.to_s
        labels[:external_dependencies] = bool_as_label(worker.worker_has_external_dependencies?)
        labels[:feature_category] = worker.get_feature_category.to_s

        resource_boundary = worker.get_worker_resource_boundary
        labels[:boundary] = resource_boundary == :unknown ? "" : resource_boundary.to_s

        if worker_class.respond_to?(:get_sidekiq_options)
          shard_name, _ = Gitlab::SidekiqSharding::Router.get_shard_instance(worker_class.get_sidekiq_options['store'])
          labels[:destination_shard_redis] = shard_name
        end

        labels
      end

      def bool_as_label(value)
        value ? TRUE_LABEL : FALSE_LABEL
      end
    end
  end
end
