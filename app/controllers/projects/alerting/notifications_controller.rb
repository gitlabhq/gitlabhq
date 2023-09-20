# frozen_string_literal: true

module Projects
  module Alerting
    class NotificationsController < Projects::ApplicationController
      include ActionController::HttpAuthentication::Basic

      respond_to :json

      skip_before_action :verify_authenticity_token
      skip_before_action :project

      prepend_before_action :repository, :project_without_auth

      feature_category :incident_management
      urgency :low, [:create]

      def create
        token = extract_alert_manager_token(request)
        result = notify_service.execute(token, integration)
        has_something_to_return = result.success? && result.http_status != :created

        if has_something_to_return
          render json: AlertManagement::AlertSerializer.new.represent(result.payload[:alerts]), code: result.http_status
        else
          head result.http_status
        end
      end

      private

      def project_without_auth
        @project ||= Project
          .find_by_full_path("#{params[:namespace_id]}/#{params[:project_id]}")
      end

      def extract_alert_manager_token(request)
        extract_bearer_token(request) || extract_basic_auth_token(request)
      end

      def extract_bearer_token(request)
        Doorkeeper::OAuth::Token.from_bearer_authorization(request)
      end

      def extract_basic_auth_token(request)
        _username, token = user_name_and_password(request)

        token
      end

      def notify_service
        notify_service_class.new(project, notification_payload)
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

      def integration
        AlertManagement::HttpIntegrationsFinder.new(
          project,
          endpoint_identifier: params[:endpoint_identifier],
          active: true
        ).execute.first
      end

      def notification_payload
        @notification_payload ||= params.permit![:notification]
      end
    end
  end
end
