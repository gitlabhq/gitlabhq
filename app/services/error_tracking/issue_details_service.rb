# frozen_string_literal: true

module ErrorTracking
  class IssueDetailsService < ErrorTracking::BaseService
    include Gitlab::Routing
    include Gitlab::Utils::StrongMemoize

    private

    def perform
      response = find_issue_details(params[:issue_id])

      compose_response(response) do
        # The gitlab_issue attribute can contain an absolute GitLab url from the Sentry Client
        # here we overwrite that in favor of our own data if we have it
        response[:issue].gitlab_issue = gitlab_issue_url if gitlab_issue_url
      end
    end

    def gitlab_issue_url
      strong_memoize(:gitlab_issue_url) do
        # Use the absolute url to match the GitLab issue url that the Sentry api provides
        project_issue_url(project, gitlab_issue.iid) if gitlab_issue
      end
    end

    def gitlab_issue
      strong_memoize(:gitlab_issue) do
        SentryIssueFinder
          .new(project, current_user: current_user)
          .execute(params[:issue_id])
          &.issue
      end
    end

    def parse_response(response)
      { issue: response[:issue] }
    end

    def find_issue_details(issue_id)
      # There are 2 types of the data source for the error tracking feature:
      #
      # * When integrated error tracking is enabled, we use the application database
      #   to read and save error tracking data.
      #
      # * When integrated error tracking is disabled we call
      #   project_error_tracking_setting method which works with Sentry API.
      #
      # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/329596
      #
      if project_error_tracking_setting.integrated_client?
        handle_error_repository_exceptions do
          error = error_repository.find_error(issue_id)
          { issue: error }
        end
      else
        project_error_tracking_setting.issue_details(issue_id: issue_id)
      end
    end
  end
end
