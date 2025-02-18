# frozen_string_literal: true

class AddClusterAgentMigrationsIssueFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_concurrent_foreign_key :cluster_agent_migrations, :issues, column: :issue_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :cluster_agent_migrations, column: :issue_id
    end
  end
end
