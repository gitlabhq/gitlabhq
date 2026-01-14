# frozen_string_literal: true

class RemoveAiActiveContextConnectionForeignKey < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.9'

  def up
    remove_partitioned_foreign_key(
      :p_ai_active_context_code_repositories,
      column: :connection_id
    )
  end

  def down
    add_concurrent_partitioned_foreign_key(
      :p_ai_active_context_code_repositories,
      :ai_active_context_connections,
      column: :connection_id,
      on_delete: :nullify
    )
  end
end
