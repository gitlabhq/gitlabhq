# frozen_string_literal: true

module Gitlab
  module JiraImport
    class IssuesImporter < BaseImporter
      # Jira limits max items per request to be fetched to 100
      # see https://jira.atlassian.com/browse/JRACLOUD-67570
      # We set it to 1000 in case they change their mind.
      BATCH_SIZE = 1000

      attr_reader :imported_items_cache_key, :start_at, :job_waiter

      def initialize(project, client = nil)
        super
        # get cached start_at value, or zero if not cached yet
        @start_at = Gitlab::JiraImport.get_issues_next_start_at(project.id)
        @imported_items_cache_key = JiraImport.already_imported_cache_key(:issues, project.id)
        @job_waiter = JobWaiter.new
        @issue_type = ::WorkItems::Type.default_issue_type
      end

      def execute
        import_issues
      end

      private

      def import_issues
        return job_waiter if jira_last_page_reached?

        issues = fetch_issues(start_at)
        update_start_at_with(issues)

        schedule_issue_import_workers(issues)
      end

      def jira_last_page_reached?
        start_at < 0
      end

      def update_start_at_with(issues)
        @start_at += issues.size

        # store -1 if this is the last page to be imported, so no more `ImportIssuesWorker` workers are scheduled
        # from Gitlab::JiraImport::Stage::ImportIssuesWorker#perform
        @start_at = -1 if issues.blank?
        Gitlab::JiraImport.store_issues_next_started_at(project.id, start_at)
      end

      def schedule_issue_import_workers(issues)
        next_iid = Issue.with_namespace_iid_supply(project.project_namespace, &:next_value)

        issues.each do |jira_issue|
          # Technically it's possible that the same work is performed multiple
          # times, as Sidekiq doesn't guarantee there will ever only be one
          # instance of a job or if for some reason the paginated results
          # returned from Jira include issues there were returned before.
          # For such cases we exit early if issue was already imported.
          next if already_imported?(jira_issue.id)

          begin
            issue_attrs = IssueSerializer.new(
              project,
              jira_issue,
              running_import.user_id,
              @issue_type,
              { iid: next_iid }
            ).execute

            Gitlab::JiraImport::ImportIssueWorker.perform_async(project.id, jira_issue.id, issue_attrs, job_waiter.key)

            job_waiter.jobs_remaining += 1

            next_iid = Issue.with_namespace_iid_supply(project.project_namespace, &:next_value)

            # Mark the issue as imported immediately so we don't end up
            # importing it multiple times within same import.
            # These ids are cleaned-up when import finishes.
            # see Gitlab::JiraImport::Stage::FinishImportWorker
            mark_as_imported(jira_issue.id)
          rescue StandardError => ex
            # handle exceptionn here and skip the failed to import issue, instead of
            # failing to import the entire batch of issues

            # track the failed to import issue.
            Gitlab::ErrorTracking.track_exception(ex, project_id: project.id)
            JiraImport.increment_issue_failures(project.id)
          end
        end

        job_waiter
      end

      def fetch_issues(start_at)
        client.Issue.jql("PROJECT='#{jira_project_key}' ORDER BY created ASC", { max_results: BATCH_SIZE, start_at: start_at })
      end
    end
  end
end
