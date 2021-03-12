# frozen_string_literal: true

module JiraConnectHelper
  def jira_connect_app_data(subscriptions)
    skip_groups = subscriptions.map(&:namespace_id)

    {
      groups_path: api_v4_groups_path(params: { min_access_level: Gitlab::Access::MAINTAINER, skip_groups: skip_groups }),
      subscriptions_path: jira_connect_subscriptions_path,
      users_path: current_user ? nil : jira_connect_users_path
    }
  end
end
