# frozen_string_literal: true

class AddFkOnAiAgentVersionsToAiAgents < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:ai_agent_versions, :ai_agents, column: :agent_id, on_delete: :cascade)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:ai_agent_versions, column: :agent_id, on_delete: :cascade)
    end
  end
end
