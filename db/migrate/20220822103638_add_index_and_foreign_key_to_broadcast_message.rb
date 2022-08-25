# frozen_string_literal: true

class AddIndexAndForeignKeyToBroadcastMessage < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_broadcast_messages_on_namespace_id'

  def up
    add_concurrent_index :broadcast_messages, :namespace_id, name: INDEX_NAME
    add_concurrent_foreign_key :broadcast_messages, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :broadcast_messages, column: :namespace_id
    remove_concurrent_index_by_name :broadcast_messages, name: INDEX_NAME
  end
end
