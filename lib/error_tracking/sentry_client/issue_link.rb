# frozen_string_literal: true

module ErrorTracking
  class SentryClient
    module IssueLink
      # Creates a link in Sentry corresponding to the provided
      # Sentry issue and GitLab issue
      # @param integration_id [Integer, nil] Representing a global
      #          GitLab integration in Sentry. Nil for plugins.
      # @param sentry_issue_id [Integer] Id for an issue from Sentry
      # @param issue [Issue] Issue for which the link should be created
      def create_issue_link(integration_id, sentry_issue_id, issue)
        return create_plugin_link(sentry_issue_id, issue) unless integration_id

        create_global_integration_link(integration_id, sentry_issue_id, issue)
      end

      private

      def create_global_integration_link(integration_id, sentry_issue_id, issue)
        issue_link_url = global_integration_link_api_url(integration_id, sentry_issue_id)

        params = {
          project: issue.project.id,
          externalIssue: "#{issue.project.id}##{issue.iid}"
        }

        http_put(issue_link_url, params)
      end

      def global_integration_link_api_url(integration_id, sentry_issue_id)
        issue_link_url = URI(url)
        issue_link_url.path = "/api/0/groups/#{sentry_issue_id}/integrations/#{integration_id}/"

        issue_link_url
      end

      def create_plugin_link(sentry_issue_id, issue)
        issue_link_url = plugin_link_api_url(sentry_issue_id)

        http_post(issue_link_url, issue_id: issue.iid)
      end

      def plugin_link_api_url(sentry_issue_id)
        issue_link_url = URI(url)
        issue_link_url.path = "/api/0/issues/#{sentry_issue_id}/plugins/gitlab/link/"

        issue_link_url
      end
    end
  end
end
