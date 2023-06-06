# frozen_string_literal: true

class RemoveBroadcastMessagesNamespaceIdColumn < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_broadcast_messages_on_namespace_id'

  def up
    remove_column :broadcast_messages, :namespace_id
  end

  def down
    add_column :broadcast_messages, :namespace_id, :bigint unless column_exists?(:broadcast_messages, :namespace_id)

    add_concurrent_index :broadcast_messages, :namespace_id, name: INDEX_NAME
  end
end
