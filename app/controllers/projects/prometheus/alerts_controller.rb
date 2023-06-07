# frozen_string_literal: true

module Projects
  module Prometheus
    class AlertsController < Projects::ApplicationController
      respond_to :json

      protect_from_forgery except: [:notify]

      skip_before_action :project, only: [:notify]

      prepend_before_action :repository, :project_without_auth, only: [:notify]

      before_action :authorize_read_prometheus_alerts!, except: [:notify]

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

      def extract_alert_manager_token(request)
        Doorkeeper::OAuth::Token.from_bearer_authorization(request)
      end

      def project_without_auth
        @project ||= Project
          .find_by_full_path("#{params[:namespace_id]}/#{params[:project_id]}")
      end
    end
  end
end
