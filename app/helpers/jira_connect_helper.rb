# frozen_string_literal: true

module JiraConnectHelper
  def new_jira_connect_ui?
    Feature.enabled?(:new_jira_connect_ui, type: :development, default_enabled: :yaml)
  end

  def jira_connect_app_data
    {
      groups_path: api_v4_groups_path(params: { min_access_level: Gitlab::Access::MAINTAINER })
    }
  end
end
