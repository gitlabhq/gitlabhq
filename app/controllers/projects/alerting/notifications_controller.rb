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

        head result.http_status
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
        notify_service_class.new(project, current_user, notification_payload)
      end

      def notify_service_class
        # We are tracking the consolidation of these services in
        # https://gitlab.com/groups/gitlab-org/-/epics/3360
        # to get rid of this workaround.
        if Projects::Prometheus::Alerts::NotifyService.processable?(notification_payload)
          Projects::Prometheus::Alerts::NotifyService
        else
          Projects::Alerting::NotifyService
        end
      end

      def notification_payload
        @notification_payload ||= params.permit![:notification]
      end
    end
  end
end
