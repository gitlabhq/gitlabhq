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

      def validate_query
        respond_to do |format|
          format.json do
            result = prometheus_adapter.query(:validate, params[:query])

            if result.any?
              render json: result
            else
              head :no_content
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
            metrics = project.prometheus_metrics
            response = {}
            if metrics.any?
              response[:metrics] = PrometheusMetricSerializer.new(project: project)
                                     .represent(metrics.order(created_at: :asc))
            end

            render json: response
          end
        end
      end

      def create
        @metric = project.prometheus_metrics.create(metrics_params)
        if @metric.persisted?
          redirect_to edit_project_service_path(project, PrometheusService),
                      notice: 'Metric was successfully added.'
        else
          render 'new'
        end
      end

      def update
        @metric = project.prometheus_metrics.find(params[:id])
        @metric.update(metrics_params)

        if @metric.persisted?
          redirect_to edit_project_service_path(project, PrometheusService),
                      notice: 'Metric was successfully updated.'
        else
          render 'edit'
        end
      end

      def edit
        @metric = project.prometheus_metrics.find(params[:id])
      end

      def destroy
        metric = project.prometheus_metrics.find(params[:id])
        metric.destroy

        respond_to do |format|
          format.html do
            redirect_to edit_project_service_path(project, PrometheusService), status: 303
          end
          format.json do
            head :ok
          end
        end
      end

      private

      def metrics_params
        params.require(:prometheus_metric).permit(:title, :query, :y_label, :unit, :legend, :group)
      end

      def prometheus_adapter
        @prometheus_adapter ||= ::Prometheus::AdapterService.new(project).prometheus_adapter
      end

      def require_prometheus_metrics!
        render_404 unless prometheus_adapter.can_query?
      end
    end
  end
end
