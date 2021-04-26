# frozen_string_literal: true

module Gitlab
  module JiraImport
    class LabelsImporter < BaseImporter
      attr_reader :job_waiter

      MAX_LABELS = 500

      def initialize(project)
        super
        @job_waiter = JobWaiter.new
      end

      def execute
        cache_import_label(project)
        import_jira_labels
      end

      private

      def cache_import_label(project)
        label = project.jira_imports.by_jira_project_key(jira_project_key).last.label
        raise Projects::ImportService::Error, _('Failed to find import label for Jira import.') unless label

        JiraImport.cache_import_label_id(project.id, label.id)
      end

      def import_jira_labels
        start_at = 0
        loop do
          break if process_jira_page(start_at)

          start_at += MAX_LABELS
        end

        job_waiter
      end

      def process_jira_page(start_at)
        request = "/rest/api/2/label?maxResults=#{MAX_LABELS}&startAt=#{start_at}"
        response = client.get(request)

        return true if response['values'].blank?
        return true unless response.key?('isLast')

        Gitlab::JiraImport::HandleLabelsService.new(project, response['values']).execute

        response['isLast']
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, project_id: project.id, request: request)
      end
    end
  end
end
