# frozen_string_literal: true

module JiraImport
  class UsersMapper
    attr_reader :project, :jira_users

    def initialize(project, jira_users)
      @project = project
      @jira_users = jira_users
    end

    def execute
      jira_users.to_a.map do |jira_user|
        {
          jira_account_id: jira_user['accountId'],
          jira_display_name: jira_user['displayName'],
          jira_email: jira_user['emailAddress'],
          gitlab_id: match_user(jira_user)
        }
      end
    end

    private

    # TODO: Matching user by email and displayName will be done as the part
    # of follow-up issue: https://gitlab.com/gitlab-org/gitlab/-/issues/219023
    def match_user(jira_user)
      nil
    end
  end
end
