# frozen_string_literal: true

module Projects
  module IncidentManagement
    class PagerDutyIncidentsController < Projects::ApplicationController
      respond_to :json

      skip_before_action :verify_authenticity_token
      skip_before_action :project

      prepend_before_action :project_without_auth

      def create
        result = ServiceResponse.success(http_status: :accepted)

        unless Feature.enabled?(:pagerduty_webhook, @project)
          result = ServiceResponse.error(message: 'Unauthorized', http_status: :unauthorized)
        end

        head result.http_status
      end

      private

      def project_without_auth
        @project ||= Project
          .find_by_full_path("#{params[:namespace_id]}/#{params[:project_id]}")
      end
    end
  end
end
