# frozen_string_literal: true

class AddWorkspaceSudoAccessToWorkspaceAgentConfigs < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :workspaces_agent_configs, :allow_privilege_escalation, :boolean,
        default: false, null: false, if_not_exists: true
      add_column :workspaces_agent_configs, :use_kubernetes_user_namespaces, :boolean,
        default: false, null: false, if_not_exists: true
      add_column :workspaces_agent_configs, :default_runtime_class, :text, default: "", null: false, if_not_exists: true
      add_column :workspaces_agent_configs, :annotations, :jsonb, default: {}, null: false, if_not_exists: true
      add_column :workspaces_agent_configs, :labels, :jsonb, default: {}, null: false, if_not_exists: true
    end
    # Kubernetes runtime class names are limited to 253 characters
    add_text_limit :workspaces_agent_configs, :default_runtime_class, 253
  end

  def down
    with_lock_retries do
      remove_column :workspaces_agent_configs, :allow_privilege_escalation, if_exists: true
      remove_column :workspaces_agent_configs, :use_kubernetes_user_namespaces, if_exists: true
      remove_column :workspaces_agent_configs, :default_runtime_class, if_exists: true
      remove_column :workspaces_agent_configs, :annotations, if_exists: true
      remove_column :workspaces_agent_configs, :labels, if_exists: true
    end
  end
end
