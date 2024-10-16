# frozen_string_literal: true

class AddDependencyProxyBlobStatesGroupIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :dependency_proxy_blob_states, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :dependency_proxy_blob_states, column: :group_id
    end
  end
end
