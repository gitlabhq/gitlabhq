# frozen_string_literal: true

module IncidentManagement
  class ProcessAlertWorker
    include ApplicationWorker

    queue_namespace :incident_management
    feature_category :incident_management

    def perform(project_id, alert)
      project = find_project(project_id)
      return unless project

      create_issue(project, alert)
    end

    private

    def find_project(project_id)
      Project.find_by_id(project_id)
    end

    def create_issue(project, alert)
      IncidentManagement::CreateIssueService
        .new(project, alert)
        .execute
    end
  end
end
