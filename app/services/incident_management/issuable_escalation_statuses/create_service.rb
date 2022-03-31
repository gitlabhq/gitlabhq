# frozen_string_literal: true

module IncidentManagement
  module IssuableEscalationStatuses
    class CreateService < ::BaseProjectService
      def initialize(issue)
        @issue = issue

        super(project: issue.project)
      end

      def execute
        escalation_status = BuildService.new(issue).execute

        if escalation_status.save
          ServiceResponse.success(payload: { escalation_status: escalation_status })
        else
          ServiceResponse.error(message: escalation_status.errors&.full_messages)
        end
      end

      private

      attr_reader :issue
    end
  end
end
