# frozen_string_literal: true

module JiraImport
  class CloudUsersMapperService < UsersMapperService
    private

    def base_path
      @base_path ||= client.options[:context_path].to_s
    end

    def url
      "#{base_path}/rest/api/2/users?maxResults=#{MAX_USERS}&startAt=#{start_at.to_i}"
    end

    def jira_user_id(jira_user)
      jira_user['accountId']
    end

    def jira_user_name(jira_user)
      jira_user['displayName']
    end
  end
end
