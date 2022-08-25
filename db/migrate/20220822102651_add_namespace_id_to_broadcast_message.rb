# frozen_string_literal: true

class AddNamespaceIdToBroadcastMessage < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :broadcast_messages, :namespace_id, :bigint
  end
end
