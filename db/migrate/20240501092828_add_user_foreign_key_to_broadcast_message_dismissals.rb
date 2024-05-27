# frozen_string_literal: true

class AddUserForeignKeyToBroadcastMessageDismissals < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_broadcast_message_dismissals, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_broadcast_message_dismissals, column: :user_id
    end
  end
end
