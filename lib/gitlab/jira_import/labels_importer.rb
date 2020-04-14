# frozen_string_literal: true

module Gitlab
  module JiraImport
    class LabelsImporter < BaseImporter
      attr_reader :job_waiter

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
        raise Projects::ImportService::Error, _('Failed to find import label for jira import.') unless label

        JiraImport.cache_import_label_id(project.id, label.id)
      end

      def import_jira_labels
        # todo: import jira labels, see https://gitlab.com/gitlab-org/gitlab/-/issues/212651
        job_waiter
      end
    end
  end
end
