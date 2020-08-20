# frozen_string_literal: true

module JiraImport
  class CloudUsersMapperService < UsersMapperService
    private

    def url
      "/rest/api/2/users?maxResults=#{MAX_USERS}&startAt=#{start_at.to_i}"
    end

    def jira_user_id(jira_user)
      jira_user['accountId']
    end

    def jira_user_name(jira_user)
      jira_user['displayName']
    end
  end
end
