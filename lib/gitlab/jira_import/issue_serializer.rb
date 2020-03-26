# frozen_string_literal: true

module Gitlab
  module JiraImport
    class IssueSerializer
      def initialize(project, jira_issue, params = {})
      end

      def execute
        # this is going to be implemented in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27201
        {}
      end
    end
  end
end
