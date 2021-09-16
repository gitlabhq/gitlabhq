# frozen_string_literal: true

class AddAgentProjectAuthorizationsForeignKeys < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :agent_project_authorizations, :projects, column: :project_id
    add_concurrent_foreign_key :agent_project_authorizations, :cluster_agents, column: :agent_id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :agent_project_authorizations, column: :project_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :agent_project_authorizations, column: :agent_id
    end
  end
end
