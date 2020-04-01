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
        create_import_label(project)
        import_jira_labels
      end

      private

      def create_import_label(project)
        label = Labels::CreateService.new(build_label_attrs(project)).execute(project: project)
        raise Projects::ImportService::Error, _('Failed to create import label for jira import.') unless label

        JiraImport.cache_import_label_id(project.id, label.id)
      end

      def build_label_attrs(project)
        import_start_time = project&.import_state&.last_update_started_at || Time.now
        title = "jira-import-#{import_start_time.strftime('%Y-%m-%d-%H-%M-%S')}"
        description = "Label for issues that were imported from jira on #{import_start_time.strftime('%Y-%m-%d %H:%M:%S')}"
        color = "#{Label.color_for(title)}"

        { title: title, description: description, color: color }
      end

      def import_jira_labels
        # todo: import jira labels, see https://gitlab.com/gitlab-org/gitlab/-/issues/212651
        job_waiter
      end
    end
  end
end
