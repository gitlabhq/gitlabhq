# frozen_string_literal: true

class CreateZoektReplicasNamespaceFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  def up
    add_concurrent_foreign_key :zoekt_replicas, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :zoekt_replicas, column: :namespace_id
    end
  end
end
