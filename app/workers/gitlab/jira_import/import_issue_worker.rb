# frozen_string_literal: true

module Gitlab
  module JiraImport
    class ImportIssueWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include Gitlab::JiraImport::QueueOptions
      include Gitlab::Import::NotifyUponDeath

      loggable_arguments 3

      def perform(project_id, jira_issue_id, issue_attributes, waiter_key)
        project = Project.find_by_id(project_id)
        return unless project

        create_issue(project, issue_attributes)
      rescue StandardError => ex
        # Todo: Record jira issue id(or better jira issue key),
        # so that we can report the list of failed to import issues to the user
        # see https://gitlab.com/gitlab-org/gitlab/-/issues/211653
        #
        # It's possible the project has been deleted since scheduling this
        # job. In this case we'll just skip creating the issue.
        Gitlab::ErrorTracking.track_exception(ex, project_id: project_id)
        JiraImport.increment_issue_failures(project_id)
      ensure
        # ensure we notify job waiter that the job has finished
        JobWaiter.notify(waiter_key, jid, ttl: Gitlab::Import::JOB_WAITER_TTL) if waiter_key
      end

      private

      def create_issue(project, issue_attributes)
        label_ids = issue_attributes.delete('label_ids').to_a.map(&:to_i)
        import_label_id = JiraImport.get_import_label_id(project.id)
        label_ids << import_label_id.to_i if import_label_id

        attributes = issue_attributes.symbolize_keys.merge(
          label_ids: label_ids,
          importing: true
        )

        project.issues.create!(attributes)
      end
    end
  end
end
