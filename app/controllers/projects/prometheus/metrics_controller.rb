# frozen_string_literal: true

module Projects
  module Prometheus
    class MetricsController < Projects::ApplicationController
      before_action :authorize_admin_project!
      before_action :require_prometheus_metrics!

      feature_category :metrics

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

      def validate_query
        respond_to do |format|
          format.json do
            result = prometheus_adapter.query(:validate, params[:query])

            if result
              render json: result
            else
              head :accepted
            end
          end
        end
      end

      def new
        @metric = project.prometheus_metrics.new
      end

      def index
        respond_to do |format|
          format.json do
            metrics = ::PrometheusMetricsFinder.new(
              project: project,
              ordered: true
            ).execute.to_a

            response = {}
            if metrics.any?
              response[:metrics] = ::PrometheusMetricSerializer
                                     .new(project: project)
                                     .represent(metrics)
            end

            render json: response
          end
        end
      end

      def create
        @metric = project.prometheus_metrics.create(
          metrics_params.to_h.symbolize_keys
        )

        if @metric.persisted?
          redirect_to edit_project_service_path(project, ::Integrations::Prometheus),
                      notice: _('Metric was successfully added.')
        else
          render 'new'
        end
      end

      def update
        @metric = update_metrics_service(prometheus_metric).execute

        if @metric.persisted?
          redirect_to edit_project_service_path(project, ::Integrations::Prometheus),
                      notice: _('Metric was successfully updated.')
        else
          render 'edit'
        end
      end

      def edit
        @metric = prometheus_metric
      end

      def destroy
        destroy_metrics_service(prometheus_metric).execute

        respond_to do |format|
          format.html do
            redirect_to edit_project_service_path(project, ::Integrations::Prometheus), status: :see_other
          end
          format.json do
            head :ok
          end
        end
      end

      private

      def prometheus_adapter
        @prometheus_adapter ||= ::Gitlab::Prometheus::Adapter.new(project, project.deployment_platform&.cluster).prometheus_adapter
      end

      def require_prometheus_metrics!
        render_404 unless prometheus_adapter&.can_query?
      end

      def prometheus_metric
        @prometheus_metric ||= ::PrometheusMetricsFinder.new(id: params[:id]).execute.first
      end

      def update_metrics_service(metric)
        ::Projects::Prometheus::Metrics::UpdateService.new(metric, metrics_params)
      end

      def destroy_metrics_service(metric)
        ::Projects::Prometheus::Metrics::DestroyService.new(metric)
      end

      def metrics_params
        params.require(:prometheus_metric).permit(:title, :query, :y_label, :unit, :legend, :group)
      end
    end
  end
end
