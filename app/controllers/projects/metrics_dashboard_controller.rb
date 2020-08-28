# frozen_string_literal: true
module Projects
  class MetricsDashboardController < Projects::ApplicationController
    # Metrics dashboard code is in the process of being decoupled from environments
    # and is getting moved to this controller. Some code may be duplicated from
    # app/controllers/projects/environments_controller.rb
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/226002 for more details.

    include Gitlab::Utils::StrongMemoize

    before_action :authorize_metrics_dashboard!
    before_action do
      push_frontend_feature_flag(:prometheus_computed_alerts)
      push_frontend_feature_flag(:disable_metric_dashboard_refresh_rate)
    end

    def show
      if environment
        render 'projects/environments/metrics'
      elsif default_environment
        redirect_to project_metrics_dashboard_path(project, environment: default_environment)
      else
        render 'projects/environments/empty_metrics'
      end
    end

    private

    def environment
      strong_memoize(:environment) do
        project.environments.find(params[:environment]) if params[:environment]
      end
    end

    def default_environment
      strong_memoize(:default_environment) do
        project.default_environment
      end
    end
  end
end
