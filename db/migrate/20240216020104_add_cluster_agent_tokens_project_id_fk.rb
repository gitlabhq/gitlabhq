# frozen_string_literal: true

class AddClusterAgentTokensProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :cluster_agent_tokens, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :cluster_agent_tokens, column: :project_id
    end
  end
end
