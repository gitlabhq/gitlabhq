# frozen_string_literal: true

module IncidentManagement
  module PagerDuty
    class CreateIncidentIssueService < BaseService
      include IncidentManagement::Settings

      def initialize(project, incident_payload)
        super(project, Users::Internal.alert_bot, incident_payload)
      end

      def execute
        return forbidden unless webhook_available?

        create_incident
      end

      private

      alias_method :incident_payload, :params

      def create_incident
        ::IncidentManagement::Incidents::CreateService.new(
          project,
          current_user,
          title: issue_title,
          description: issue_description
        ).execute
      end

      def webhook_available?
        incident_management_setting.pagerduty_active?
      end

      def forbidden
        ServiceResponse.error(message: 'Forbidden', http_status: :forbidden)
      end

      def issue_title
        incident_payload['title']
      end

      def issue_description
        Gitlab::IncidentManagement::PagerDuty::IncidentIssueDescription.new(incident_payload).to_s
      end
    end
  end
end
