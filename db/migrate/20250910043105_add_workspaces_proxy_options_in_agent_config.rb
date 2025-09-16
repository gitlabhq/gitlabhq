# frozen_string_literal: true

class AddWorkspacesProxyOptionsInAgentConfig < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    add_column :workspaces_agent_configs, :gitlab_workspaces_proxy_http_enabled, :boolean,
      null: false, default: true, if_not_exists: true
    add_column :workspaces_agent_configs, :gitlab_workspaces_proxy_ssh_enabled, :boolean,
      null: false, default: true, if_not_exists: true
  end

  def down
    remove_column :workspaces_agent_configs, :gitlab_workspaces_proxy_http_enabled, if_exists: true
    remove_column :workspaces_agent_configs, :gitlab_workspaces_proxy_ssh_enabled, if_exists: true
  end
end
