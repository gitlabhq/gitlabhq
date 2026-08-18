# frozen_string_literal: true

class AddProjectForeignKeyToAiAgentIdentities < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ai_agent_identities, :projects,
      column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ai_agent_identities, column: :project_id
    end
  end
end
