# frozen_string_literal: true

class RemoveNamespacesBroadcastMessagesNamespaceIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:broadcast_messages, :namespaces, name: "fk_7bf2ec43da")

    with_lock_retries do
      remove_foreign_key_if_exists(:broadcast_messages, :namespaces,
        name: "fk_7bf2ec43da", reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:broadcast_messages, :namespaces,
      name: "fk_7bf2ec43da", column: :namespace_id,
      target_column: :id, on_delete: :cascade)
  end
end
