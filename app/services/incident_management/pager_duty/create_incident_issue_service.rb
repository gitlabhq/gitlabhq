# frozen_string_literal: true

module IncidentManagement
  module PagerDuty
    class CreateIncidentIssueService < BaseService
      include IncidentManagement::Settings

      def initialize(project, incident_payload)
        super(project, User.alert_bot, incident_payload)
      end

      def execute
        return forbidden unless webhook_available?

        issue = create_issue
        return error(issue.errors.full_messages.to_sentence, issue) unless issue.valid?

        success(issue)
      end

      private

      alias_method :incident_payload, :params

      def create_issue
        label_result = find_or_create_incident_label

        # Create an unlabelled issue if we couldn't create the label
        # due to a race condition.
        # See https://gitlab.com/gitlab-org/gitlab-foss/issues/65042
        extra_params = label_result.success? ? { label_ids: [label_result.payload[:label].id] } : {}

        Issues::CreateService.new(
          project,
          current_user,
          title: issue_title,
          description: issue_description,
          **extra_params
        ).execute
      end

      def webhook_available?
        incident_management_setting.pagerduty_active?
      end

      def forbidden
        ServiceResponse.error(message: 'Forbidden', http_status: :forbidden)
      end

      def find_or_create_incident_label
        ::IncidentManagement::CreateIncidentLabelService.new(project, current_user).execute
      end

      def issue_title
        incident_payload['title']
      end

      def issue_description
        Gitlab::IncidentManagement::PagerDuty::IncidentIssueDescription.new(incident_payload).to_s
      end

      def success(issue)
        ServiceResponse.success(payload: { issue: issue })
      end

      def error(message, issue = nil)
        ServiceResponse.error(payload: { issue: issue }, message: message)
      end
    end
  end
end
