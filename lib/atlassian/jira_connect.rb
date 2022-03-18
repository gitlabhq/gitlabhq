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

      private

      def gitlab_host
        Gitlab.config.gitlab.host
      end
    end
  end
end
