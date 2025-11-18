# frozen_string_literal: true

class RemoveNamespacesDependencyProxyBlobStatesGroupIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_95ee495fd6"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:dependency_proxy_blob_states, :namespaces,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:dependency_proxy_blob_states, :namespaces,
      name: FOREIGN_KEY_NAME, column: :group_id,
      target_column: :id, on_delete: :cascade)
  end
end
