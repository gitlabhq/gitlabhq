# frozen_string_literal: true

module IncidentManagement
  module PagerDuty
    class ProcessIncidentWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3

      queue_namespace :incident_management
      feature_category :incident_management

      def perform(project_id, incident_payload)
        return unless project_id

        project = find_project(project_id)
        return unless project

        result = create_issue(project, incident_payload)

        log_error(result) if result.error?
      end

      private

      def find_project(project_id)
        Project.find_by_id(project_id)
      end

      def create_issue(project, incident_payload)
        ::IncidentManagement::PagerDuty::CreateIncidentIssueService
          .new(project, incident_payload)
          .execute
      end

      def log_error(result)
        Gitlab::AppLogger.warn(
          message: 'Cannot create issue for PagerDuty incident',
          issue_errors: result.message
        )
      end
    end
  end
end
