# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module MetricsHelper
      TRUE_LABEL = "yes"
      FALSE_LABEL = "no"

      private

      def create_labels(worker_class, queue, job)
        worker_name = (job['wrapped'].presence || worker_class).to_s
        worker = find_worker(worker_name, worker_class)

        labels = { queue: queue.to_s,
                   worker: worker_name,
                   urgency: "",
                   external_dependencies: FALSE_LABEL,
                   feature_category: "",
                   boundary: "" }

        return labels unless worker.respond_to?(:get_urgency)

        labels[:urgency] = worker.get_urgency.to_s
        labels[:external_dependencies] = bool_as_label(worker.worker_has_external_dependencies?)

        feature_category = worker.get_feature_category
        labels[:feature_category] = feature_category.to_s

        resource_boundary = worker.get_worker_resource_boundary
        labels[:boundary] = resource_boundary == :unknown ? "" : resource_boundary.to_s

        labels
      end

      def bool_as_label(value)
        value ? TRUE_LABEL : FALSE_LABEL
      end

      def find_worker(worker_name, worker_class)
        Gitlab::SidekiqConfig::DEFAULT_WORKERS.fetch(worker_name, worker_class)
      end
    end
  end
end
