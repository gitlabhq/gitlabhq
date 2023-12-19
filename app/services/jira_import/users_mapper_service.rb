# frozen_string_literal: true

module JiraImport
  class UsersMapperService
    include Gitlab::Utils::StrongMemoize

    # MAX_USERS must match the pageSize value in app/assets/javascripts/jira_import/utils/constants.js
    MAX_USERS = 50

    # The class is called from UsersImporter and small batches of users are expected
    # In case the mapping of a big batch of users is expected to be passed here
    # the implementation needs to change here and handles the matching in batches
    def initialize(current_user, project, start_at)
      @current_user = current_user
      @project = project
      @jira_integration = project.jira_integration
      @start_at = start_at
    end

    def execute
      jira_users.to_a.map do |jira_user|
        {
          jira_account_id: jira_user_id(jira_user),
          jira_display_name: jira_user_name(jira_user),
          jira_email: jira_user['emailAddress']
        }.merge(gitlab_id: find_gitlab_id(jira_user))
      end
    end

    private

    attr_reader :current_user, :project, :jira_integration, :start_at

    def jira_users
      @jira_users ||= client.get(url)
    end

    def client
      @client ||= jira_integration.client
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

    def matched_users
      strong_memoize(:matched_users) do
        jira_emails = jira_users.map { |u| u['emailAddress']&.downcase }.compact
        jira_names = jira_users.map { |u| jira_user_name(u)&.downcase }.compact

        relations = []
        relations << User.by_username(jira_names).select("users.id, users.name, users.username, users.email as user_email")
        relations << User.by_name(jira_names).select("users.id, users.name, users.username, users.email as user_email")
        relations << User.by_user_email(jira_emails).select("users.id, users.name, users.username, users.email as user_email")
        relations << User.by_emails(jira_emails).select("users.id, users.name, users.username, emails.email as user_email")

        User.from_union(relations).id_in(project_member_ids).select("users.id as user_id, users.name as name, users.username as username, user_email")
          .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/432608")
      end
    end

    def find_gitlab_id(jira_user)
      user = matched_users.find do |matched_user|
        matched_user.user_email&.downcase == jira_user['emailAddress']&.downcase ||
          matched_user.name&.downcase == jira_user_name(jira_user)&.downcase ||
          matched_user.username&.downcase == jira_user_name(jira_user)&.downcase
      end

      user&.user_id
    end

    def project_member_ids
      @project_member_ids ||= MembersFinder.new(project, current_user).execute.reselect(:user_id)
    end
  end
end
