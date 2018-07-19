module EE
  module EnvironmentsHelper
    def metrics_data(project, environment)
      ee_metrics_data = {
        "alerts-endpoint" => project_prometheus_alerts_path(project, environment_id: environment.id, format: :json),
        "prometheus-alerts-available" => "#{can?(current_user, :read_prometheus_alerts, project)}"
      }

      super.merge(ee_metrics_data)
    end
  end
end
