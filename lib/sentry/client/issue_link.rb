# frozen_string_literal: true

module Sentry
  class Client
    module IssueLink
      def create_issue_link(integration_id, sentry_issue_identifier, issue)
        issue_link_url = issue_link_api_url(integration_id, sentry_issue_identifier)

        params = {
          project: issue.project.id,
          externalIssue: "#{issue.project.id}##{issue.iid}"
        }

        http_put(issue_link_url, params)
      end

      private

      def issue_link_api_url(integration_id, sentry_issue_identifier)
        issue_link_url = URI(url)
        issue_link_url.path = "/api/0/groups/#{sentry_issue_identifier}/integrations/#{integration_id}/"

        issue_link_url
      end
    end
  end
end
