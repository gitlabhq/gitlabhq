# frozen_string_literal: true

module Projects
  module Alerting
    class NotificationsController < Projects::ApplicationController
      respond_to :json

      skip_before_action :verify_authenticity_token
      skip_before_action :project

      prepend_before_action :repository, :project_without_auth

      def create
        token = extract_alert_manager_token(request)
        result = notify_service.execute(token)

        head(response_status(result))
      end

      private

      def project_without_auth
        @project ||= Project
          .find_by_full_path("#{params[:namespace_id]}/#{params[:project_id]}")
      end

      def extract_alert_manager_token(request)
        Doorkeeper::OAuth::Token.from_bearer_authorization(request)
      end

      def notify_service
        Projects::Alerting::NotifyService
          .new(project, current_user, notification_payload)
      end

      def response_status(result)
        return :ok if result.success?

        result.http_status
      end

      def notification_payload
        params.permit![:notification]
      end
    end
  end
end
