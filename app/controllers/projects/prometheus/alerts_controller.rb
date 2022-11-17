# frozen_string_literal: true

module Projects
  module Prometheus
    class AlertsController < Projects::ApplicationController
      include MetricsDashboard

      respond_to :json

      protect_from_forgery except: [:notify]

      skip_before_action :project, only: [:notify]

      prepend_before_action :repository, :project_without_auth, only: [:notify]

      before_action :authorize_read_prometheus_alerts!, except: [:notify]
      before_action :alert, only: [:metrics_dashboard]

      feature_category :incident_management
      urgency :low

      def notify
        token = extract_alert_manager_token(request)
        result = notify_service.execute(token)

        head result.http_status
      end

      private

      def notify_service
        Projects::Prometheus::Alerts::NotifyService
          .new(project, params.permit!)
      end

      def alert
        @alert ||= alerts_finder(metric: params[:id]).execute.first || render_404
      end

      def alerts_finder(opts = {})
        Projects::Prometheus::AlertsFinder.new({
          project: project,
          environment: params[:environment_id]
        }.reverse_merge(opts))
      end

      def extract_alert_manager_token(request)
        Doorkeeper::OAuth::Token.from_bearer_authorization(request)
      end

      def project_without_auth
        @project ||= Project
          .find_by_full_path("#{params[:namespace_id]}/#{params[:project_id]}")
      end

      def metrics_dashboard_params
        {
          embedded: true,
          prometheus_alert_id: alert.id
        }
      end
    end
  end
end
