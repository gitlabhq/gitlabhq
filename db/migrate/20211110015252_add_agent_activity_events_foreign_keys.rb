# frozen_string_literal: true

class AddAgentActivityEventsForeignKeys < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :agent_activity_events, :cluster_agents, column: :agent_id, on_delete: :cascade
    add_concurrent_foreign_key :agent_activity_events, :users, column: :user_id, on_delete: :nullify
    add_concurrent_foreign_key :agent_activity_events, :projects, column: :project_id, on_delete: :nullify
    add_concurrent_foreign_key :agent_activity_events, :merge_requests, column: :merge_request_id, on_delete: :nullify
    add_concurrent_foreign_key :agent_activity_events, :cluster_agent_tokens, column: :agent_token_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :agent_activity_events, column: :agent_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :agent_activity_events, column: :user_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :agent_activity_events, column: :project_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :agent_activity_events, column: :merge_request_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :agent_activity_events, column: :agent_token_id
    end
  end
end
