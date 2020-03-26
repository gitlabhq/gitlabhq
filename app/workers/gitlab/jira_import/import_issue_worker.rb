# frozen_string_literal: true

module Gitlab
  module JiraImport
    class ImportIssueWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker
      include NotifyUponDeath
      include Gitlab::JiraImport::QueueOptions
      include Gitlab::Import::DatabaseHelpers

      def perform(project_id, jira_issue_id, issue_attributes, waiter_key)
        issue_id = insert_and_return_id(issue_attributes, Issue)
        cache_issue_mapping(issue_id, jira_issue_id, project_id)
      rescue => ex
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
        JobWaiter.notify(waiter_key, jid) if waiter_key
      end

      private

      def cache_issue_mapping(issue_id, jira_issue_id, project_id)
        cache_key = JiraImport.jira_issue_cache_key(project_id, jira_issue_id)
        Gitlab::Cache::Import::Caching.write(cache_key, issue_id)
      end
    end
  end
end
