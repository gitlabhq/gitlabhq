# frozen_string_literal: true

module IncidentManagement
  module LinkAlerts
    class DestroyService < BaseService
      # @param incident [Issue] an incident to unlink alert from
      # @param current_user [User]
      # @param alert [AlertManagement::Alert] an alert to unlink from the incident
      def initialize(incident, current_user, alert)
        @incident = incident
        @current_user = current_user
        @alert = alert

        super(project: incident.project, current_user: current_user)
      end

      def execute
        return error_no_permissions unless allowed?

        incident.alert_management_alerts.delete(alert)

        success
      end

      private

      attr_reader :alert
    end
  end
end
