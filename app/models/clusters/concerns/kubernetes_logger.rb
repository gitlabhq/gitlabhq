# frozen_string_literal: true

module Clusters
  module Concerns
    module KubernetesLogger
      def logger
        @logger ||= Gitlab::Kubernetes::Logger.build
      end

      def log_exception(error, event)
        logger.error(
          {
            exception: error.class.name,
            status_code: error.error_code,
            cluster_id: cluster&.id,
            application_id: id,
            class_name: self.class.name,
            event: event,
            message: error.message
          }
        )

        Gitlab::ErrorTracking.track_exception(error, cluster_id: cluster&.id, application_id: id)
      end
    end
  end
end
