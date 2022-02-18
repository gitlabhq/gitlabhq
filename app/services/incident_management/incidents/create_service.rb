# frozen_string_literal: true

module IncidentManagement
  module Incidents
    class CreateService < ::BaseProjectService
      ISSUE_TYPE = 'incident'

      def initialize(project, current_user, title:, description:, severity: IssuableSeverity::DEFAULT, alert: nil)
        super(project: project, current_user: current_user)

        @title = title
        @description = description
        @severity = severity
        @alert = alert
      end

      def execute
        issue = Issues::CreateService.new(
          project: project,
          current_user: current_user,
          params: {
            title: title,
            description: description,
            issue_type: ISSUE_TYPE,
            severity: severity,
            alert_management_alert: alert
          },
          spam_params: nil
        ).execute

        if alert
          return error(alert.errors.full_messages.to_sentence, issue) unless alert.valid?
        end

        return error(issue.errors.full_messages.to_sentence, issue) unless issue.valid?

        success(issue)
      end

      private

      attr_reader :title, :description, :severity, :alert

      def success(issue)
        ServiceResponse.success(payload: { issue: issue })
      end

      def error(message, issue = nil)
        ServiceResponse.error(payload: { issue: issue }, message: message)
      end
    end
  end
end
