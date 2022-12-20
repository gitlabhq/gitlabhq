# frozen_string_literal: true

module IncidentManagement
  module LinkAlerts
    class CreateService < BaseService
      # @param incident [Issue] an incident to link alerts
      # @param current_user [User]
      # @param alert_references [[String]] a list of alert references. Can be either a short reference or URL
      #   Examples:
      #     "^alert#IID"
      #     "https://gitlab.com/company/project/-/alert_management/IID/details"
      def initialize(incident, current_user, alert_references)
        @incident = incident
        @current_user = current_user
        @alert_references = alert_references

        super(project: incident.project, current_user: current_user)
      end

      def execute
        return error_no_permissions unless allowed?

        references = extract_alerts_from_references
        incident.alert_management_alerts << references if references.present?

        success
      end

      private

      attr_reader :alert_references

      def extract_alerts_from_references
        text = alert_references.join(' ')
        extractor = Gitlab::ReferenceExtractor.new(project, current_user)
        extractor.analyze(text, {})

        extractor.alerts
      end
    end
  end
end
