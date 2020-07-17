# frozen_string_literal: true
module Projects
  class MetricsDashboardController < Projects::ApplicationController
    # Metrics dashboard code is in the process of being decoupled from environments
    # and is getting moved to this controller. Some code may be duplicated from
    # app/controllers/projects/environments_controller.rb
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/226002 for more details.

    before_action :authorize_metrics_dashboard!
    before_action do
      push_frontend_feature_flag(:prometheus_computed_alerts)
      push_frontend_feature_flag(:disable_metric_dashboard_refresh_rate)
    end

    def show
      if environment
        render 'projects/environments/metrics'
      else
        render_404
      end
    end

    private

    def environment
      @environment ||=
        if params[:environment]
          project.environments.find(params[:environment])
        else
          project.default_environment
        end
    end
  end
end
