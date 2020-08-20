# frozen_string_literal: true

module JiraImport
  class ServerUsersMapperService < UsersMapperService
    private

    def url
      "/rest/api/2/user/search?username=''&maxResults=#{MAX_USERS}&startAt=#{start_at.to_i}"
    end

    def jira_user_id(jira_user)
      jira_user['key']
    end

    def jira_user_name(jira_user)
      jira_user['name']
    end
  end
end
