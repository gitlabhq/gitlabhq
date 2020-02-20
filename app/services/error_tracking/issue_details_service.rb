# frozen_string_literal: true

module ErrorTracking
  class IssueDetailsService < ErrorTracking::BaseService
    include Gitlab::Routing
    include Gitlab::Utils::StrongMemoize

    private

    def perform
      response = project_error_tracking_setting.issue_details(issue_id: params[:issue_id])

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
  end
end
