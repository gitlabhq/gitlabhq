# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module MetricsHelper
      TRUE_LABEL = "yes"
      FALSE_LABEL = "no"

      private

      def create_labels(worker_class, queue)
        labels = { queue: queue.to_s,
                   worker: worker_class.to_s,
                   urgency: "",
                   external_dependencies: FALSE_LABEL,
                   feature_category: "",
                   boundary: "" }

        return labels unless worker_class && worker_class.include?(WorkerAttributes)

        labels[:urgency] = worker_class.get_urgency.to_s
        labels[:external_dependencies] = bool_as_label(worker_class.worker_has_external_dependencies?)

        feature_category = worker_class.get_feature_category
        labels[:feature_category] = feature_category.to_s

        resource_boundary = worker_class.get_worker_resource_boundary
        labels[:boundary] = resource_boundary == :unknown ? "" : resource_boundary.to_s

        labels
      end

      def bool_as_label(value)
        value ? TRUE_LABEL : FALSE_LABEL
      end
    end
  end
end
