# frozen_string_literal: true

module IncidentManagement
  module IssuableEscalationStatuses
    class BuildService < ::BaseProjectService
      def initialize(issue)
        @issue = issue

        super(project: issue.project)
      end

      def execute
        issue.escalation_status || issue.build_incident_management_issuable_escalation_status
      end

      private

      attr_reader :issue
    end
  end
end
