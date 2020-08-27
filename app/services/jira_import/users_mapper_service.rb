# frozen_string_literal: true

module JiraImport
  class UsersMapperService
    # MAX_USERS must match the pageSize value in app/assets/javascripts/jira_import/utils/constants.js
    MAX_USERS = 50

    attr_reader :jira_service, :start_at

    def initialize(jira_service, start_at)
      @jira_service = jira_service
      @start_at = start_at
    end

    def execute
      users.to_a.map do |jira_user|
        {
          jira_account_id: jira_user_id(jira_user),
          jira_display_name: jira_user_name(jira_user),
          jira_email: jira_user['emailAddress']
        }.merge(match_user(jira_user))
      end
    end

    private

    def users
      @users ||= client.get(url)
    end

    def client
      @client ||= jira_service.client
    end

    def url
      raise NotImplementedError
    end

    def jira_user_id(jira_user)
      raise NotImplementedError
    end

    def jira_user_name(jira_user)
      raise NotImplementedError
    end

    # TODO: Matching user by email and displayName will be done as the part
    # of follow-up issue: https://gitlab.com/gitlab-org/gitlab/-/issues/219023
    def match_user(jira_user)
      { gitlab_id: nil, gitlab_username: nil, gitlab_name: nil }
    end
  end
end
