module EE
  module Projects
    module Prometheus
      module MetricsController
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
          @metric = project.prometheus_metrics.new # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end

        def index
          respond_to do |format|
            format.json do
              metrics = project.prometheus_metrics
              response = {}
              if metrics.any?
                response[:metrics] = ::PrometheusMetricSerializer.new(project: project)
                                       .represent(metrics.order(created_at: :asc))
              end

              render json: response
            end
          end
        end

        def create
          @metric = project.prometheus_metrics.create(metrics_params) # rubocop:disable Gitlab/ModuleWithInstanceVariables
          if @metric.persisted? # rubocop:disable Gitlab/ModuleWithInstanceVariables
            redirect_to edit_project_service_path(project, ::PrometheusService),
                        notice: 'Metric was successfully added.'
          else
            render 'new'
          end
        end

        def update
          @metric = project.prometheus_metrics.find(params[:id]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
          @metric = update_metrics_service(@metric).execute # rubocop:disable Gitlab/ModuleWithInstanceVariables

          if @metric.persisted? # rubocop:disable Gitlab/ModuleWithInstanceVariables
            redirect_to edit_project_service_path(project, ::PrometheusService),
                        notice: 'Metric was successfully updated.'
          else
            render 'edit'
          end
        end

        def edit
          @metric = project.prometheus_metrics.find(params[:id]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end

        def destroy
          metric = project.prometheus_metrics.find(params[:id])
          destroy_metrics_service(metric).execute

          respond_to do |format|
            format.html do
              redirect_to edit_project_service_path(project, ::PrometheusService), status: :see_other
            end
            format.json do
              head :ok
            end
          end
        end

        private

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
end
