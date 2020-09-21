# frozen_string_literal: true

module IncidentManagement
  module Incidents
    class CreateService < BaseService
      ISSUE_TYPE = 'incident'

      def initialize(project, current_user, title:, description:, severity: IssuableSeverity::DEFAULT)
        super(project, current_user)

        @title = title
        @description = description
        @severity = severity
      end

      def execute
        issue = Issues::CreateService.new(
          project,
          current_user,
          title: title,
          description: description,
          issue_type: ISSUE_TYPE
        ).execute

        return error(issue.errors.full_messages.to_sentence, issue) unless issue.valid?

        update_severity_for(issue)

        success(issue)
      end

      private

      attr_reader :title, :description, :severity

      def success(issue)
        ServiceResponse.success(payload: { issue: issue })
      end

      def error(message, issue = nil)
        ServiceResponse.error(payload: { issue: issue }, message: message)
      end

      def update_severity_for(issue)
        ::IncidentManagement::Incidents::UpdateSeverityService.new(issue, current_user, severity).execute
      end
    end
  end
end
