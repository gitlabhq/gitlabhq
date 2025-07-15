# frozen_string_literal: true

class AddForeignKeyToAiActiveContextCodeEnabledNamespaces < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.2'

  def up
    add_concurrent_partitioned_foreign_key :p_ai_active_context_code_enabled_namespaces, :namespaces,
      column: :namespace_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :p_ai_active_context_code_enabled_namespaces, column: :namespace_id
  end
end
