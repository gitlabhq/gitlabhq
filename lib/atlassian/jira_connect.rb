# frozen_string_literal: true

module Atlassian
  module JiraConnect
    class << self
      def app_name
        "GitLab for Jira (#{gitlab_host})"
      end

      def app_key
        # App key must be <= 64 characters.
        # See: https://developer.atlassian.com/cloud/jira/platform/connect-app-descriptor/#app-descriptor-structure

        "gitlab-jira-connect-#{gitlab_host}"[..63]
      end

      def display_name
        gitlab_host == 'gitlab.com' ? 'GitLab' : "GitLab (#{gitlab_host})"
      end

      private

      def gitlab_host
        return host_from_settings if Gitlab::CurrentSettings.jira_connect_proxy_url?

        Gitlab.config.gitlab.host
      end

      def host_from_settings
        uri = URI(Gitlab::CurrentSettings.jira_connect_proxy_url)

        uri.hostname + uri.path
      end
    end
  end
end
