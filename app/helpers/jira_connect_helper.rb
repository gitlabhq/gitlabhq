# frozen_string_literal: true

module JiraConnectHelper
  def new_jira_connect_ui?
    Feature.enabled?(:new_jira_connect_ui, type: :development, default_enabled: :yaml)
  end
end
