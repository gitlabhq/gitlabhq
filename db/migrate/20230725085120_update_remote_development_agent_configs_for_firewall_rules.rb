# frozen_string_literal: true

class UpdateRemoteDevelopmentAgentConfigsForFirewallRules < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :remote_development_agent_configs, :network_policy_enabled, :boolean, default: true, null: false
      add_column :remote_development_agent_configs, :gitlab_workspaces_proxy_namespace, :text,
        default: "gitlab-workspaces", null: false
    end
    # Kubernetes namespaces are limited to 63 characters
    add_text_limit :remote_development_agent_configs, :gitlab_workspaces_proxy_namespace, 63
  end

  def down
    with_lock_retries do
      remove_column :remote_development_agent_configs, :gitlab_workspaces_proxy_namespace, if_exists: true
      remove_column :remote_development_agent_configs, :network_policy_enabled, if_exists: true
    end
  end
end
