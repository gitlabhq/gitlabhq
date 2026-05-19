# frozen_string_literal: true

module IncidentManagement
  module Incidents
    class CreateService < ::BaseProjectService
      def initialize(project, current_user, title:, description:, severity: IssuableSeverity::DEFAULT, alert: nil)
        super(project: project, current_user: current_user)

        @title = title
        @description = description
        @severity = severity
        @alert = alert
      end

      def execute
        create_result = Issues::CreateService.new(
          container: project,
          current_user: current_user,
          params: {
            title: title,
            description: description,
            work_item_type: incident_work_item_type,
            severity: severity,
            alert_management_alerts: [alert].compact
          },
          perform_spam_check: false
        ).execute

        if alert
          return error(alert.errors.full_messages, create_result[:issue]) unless alert.valid?
        end

        create_result
      end

      private

      attr_reader :title, :description, :severity, :alert

      def incident_work_item_type
        ::WorkItems::TypesFramework::Provider.new(project).find_by_base_type(:incident)
      end

      def error(message, issue = nil)
        ServiceResponse.error(payload: { issue: issue }, message: message)
      end
    end
  end
end
