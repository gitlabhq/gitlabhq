module Projects
  module Prometheus
    class MetricsController < Projects::ApplicationController
      before_action :authorize_admin_project!
      before_action :require_prometheus_metrics!

      def active_common
        respond_to do |format|
          format.json do
            matched_metrics = prometheus_adapter.query(:matched_metrics) || {}

            if matched_metrics.any?
              render json: matched_metrics
            else
              head :no_content
            end
          end
        end
      end

      private

      def prometheus_adapter
        @prometheus_adapter ||= ::Prometheus::AdapterService.new(project).prometheus_adapter
      end

      def require_prometheus_metrics!
        render_404 unless prometheus_adapter.can_query?
      end
    end
  end
end
