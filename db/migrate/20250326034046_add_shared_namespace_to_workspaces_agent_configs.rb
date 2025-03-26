# frozen_string_literal: true

class AddSharedNamespaceToWorkspacesAgentConfigs < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.11'

  def up
    with_lock_retries do
      add_column :workspaces_agent_configs, :shared_namespace, :text, null: false, default: '', if_not_exists: true
    end

    add_text_limit :workspaces_agent_configs, :shared_namespace, 63
  end

  def down
    with_lock_retries do
      remove_column :workspaces_agent_configs, :shared_namespace, if_exists: true
    end
  end
end
