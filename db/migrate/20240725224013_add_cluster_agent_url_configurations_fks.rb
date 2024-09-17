# frozen_string_literal: true

class AddClusterAgentUrlConfigurationsFks < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  def up
    add_concurrent_foreign_key :cluster_agent_url_configurations, :cluster_agents, column: :agent_id
    add_concurrent_foreign_key :cluster_agent_url_configurations, :projects, column: :project_id
    add_concurrent_foreign_key :cluster_agent_url_configurations, :users, column: :created_by_user_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :cluster_agent_url_configurations, column: :agent_id
    end
    with_lock_retries do
      remove_foreign_key :cluster_agent_url_configurations, column: :project_id
    end
    with_lock_retries do
      remove_foreign_key :cluster_agent_url_configurations, column: :created_by_user_id
    end
  end
end
