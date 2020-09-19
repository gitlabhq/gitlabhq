# frozen_string_literal: true

module Atlassian
  module JiraConnect
    class << self
      def app_name
        "GitLab for Jira (#{gitlab_host})"
      end

      def app_key
        "gitlab-jira-connect-#{gitlab_host}"
      end

      private

      def gitlab_host
        Gitlab.config.gitlab.host
      end
    end
  end
end
