# frozen_string_literal: true

module Gitlab
  module JiraImport
    class IssuesImporter < BaseImporter
      # Jira limits max items per request to be fetched to 100
      # see https://jira.atlassian.com/browse/JRACLOUD-67570
      # We set it to 1000 in case they change their mind.
      BATCH_SIZE = 1000

      attr_reader :imported_items_cache_key, :start_at, :job_waiter

      def initialize(project)
        super
        @imported_items_cache_key = JiraImport.already_imported_cache_key(:issues, project.id)
        @job_waiter = JobWaiter.new
        @issue_type = ::WorkItems::Type.default_issue_type
        @jira_integration = project.jira_integration
      end

      def execute
        import_issues
      end

      private

      attr_reader :jira_integration

      def import_issues
        return job_waiter if jira_last_page_reached?

        response = fetch_issues

        return job_waiter unless response.success?

        issues = response.payload[:issues] || []

        update_pagination_state(response.payload)

        schedule_issue_import_workers(issues) if issues.any?

        job_waiter
      end

      def jira_last_page_reached?
        pagination_state = Gitlab::JiraImport.get_pagination_state(project.id)
        pagination_state[:is_last]
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

      def fetch_issues
        jql = "PROJECT='#{jira_project_key}' ORDER BY created ASC"
        pagination_state = Gitlab::JiraImport.get_pagination_state(project.id)

        params = {
          jql: jql,
          per_page: BATCH_SIZE
        }

        if jira_integration.data_fields.deployment_cloud?
          params[:next_page_token] = pagination_state[:next_page_token]
          response = ::Jira::Requests::Issues::CloudListService.new(jira_integration, params).execute
        else
          params[:page] = pagination_state[:page] || 1
          response = ::Jira::Requests::Issues::ServerListService.new(jira_integration, params).execute
        end

        response
      end

      def update_pagination_state(payload)
        Gitlab::JiraImport.store_pagination_state(project.id, {
          is_last: payload[:is_last] || payload[:issues].blank? || payload[:issues].empty?,
          next_page_token: payload[:next_page_token],
          page: payload[:page]
        })
      end
    end
  end
end
