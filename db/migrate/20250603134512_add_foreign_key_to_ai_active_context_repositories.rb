# frozen_string_literal: true

class AddForeignKeyToAiActiveContextRepositories < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.2'

  def up
    add_concurrent_partitioned_foreign_key(
      :p_ai_active_context_code_repositories,
      :ai_active_context_connections,
      column: :connection_id,
      on_delete: :nullify
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :p_ai_active_context_code_repositories,
        column: :connection_id
      )
    end
  end
end
