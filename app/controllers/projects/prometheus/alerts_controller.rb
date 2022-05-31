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
      before_action :alert, only: [:show, :metrics_dashboard]

      feature_category :incident_management
      urgency :low

      def show
        render json: serialize_as_json(alert)
      end

      def notify
        token = extract_alert_manager_token(request)
        result = notify_service.execute(token)

        if result.success?
          render json: AlertManagement::AlertSerializer.new.represent(result.payload[:alerts]), code: result.http_status
        else
          head result.http_status
        end
      end

      private

      def notify_service
        Projects::Prometheus::Alerts::NotifyService
          .new(project, params.permit!)
      end

      def serialize_as_json(alert_obj)
        serializer.represent(alert_obj)
      end

      def serializer
        PrometheusAlertSerializer
          .new(project: project, current_user: current_user)
      end

      def alerts
        alerts_finder.execute
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
