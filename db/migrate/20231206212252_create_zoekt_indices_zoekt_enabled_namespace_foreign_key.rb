# frozen_string_literal: true

class CreateZoektIndicesZoektEnabledNamespaceForeignKey < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.8'

  def up
    add_concurrent_foreign_key :zoekt_indices, :zoekt_enabled_namespaces,
      column: :zoekt_enabled_namespace_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :zoekt_indices, column: :zoekt_enabled_namespace_id
    end
  end
end
