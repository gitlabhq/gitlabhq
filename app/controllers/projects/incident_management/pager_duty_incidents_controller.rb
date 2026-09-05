# frozen_string_literal: true

module Projects
  module IncidentManagement
    class PagerDutyIncidentsController < Projects::ApplicationController
      respond_to :json

      skip_before_action :verify_authenticity_token
      skip_before_action :project

      prepend_before_action :project_without_auth

      feature_category :incident_management
      urgency :low

      def create
        result = webhook_processor.execute(params.permit(:token)[:token])

        head result.http_status
      end

      private

      def project_without_auth
        @project ||= Project
          .find_by_full_path("#{project_path_params[:namespace_id]}/#{project_path_params[:project_id]}")
      end

      def project_path_params
        params.permit(:namespace_id, :project_id)
      end

      def webhook_processor
        ::IncidentManagement::PagerDuty::ProcessWebhookService.new(project, payload)
      end

      def payload
        @payload ||= safe_params[:pager_duty_incident].to_h
      end
    end
  end
end
