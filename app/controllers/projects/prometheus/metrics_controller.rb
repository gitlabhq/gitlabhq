module Projects
  module Prometheus
    class MetricsController < Projects::ApplicationController
      before_action :authorize_admin_project!

      def active_common
        respond_to do |format|
          format.json do
            matched_metrics = prometheus_service.matched_metrics || {}

            if matched_metrics.any?
              render json: matched_metrics
            else
              head :no_content
            end
          end
        end
      end

      private

      def prometheus_service
        @prometheus_service ||= project.find_or_initialize_service('prometheus')
      end
    end
  end
end
