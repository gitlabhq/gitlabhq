# frozen_string_literal: true

class AddForeignKeyOnUserIdOnTargetedMessageDismissals < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_targeted_message_dismissals_on_user_id'

  def up
    add_concurrent_foreign_key(
      :targeted_message_dismissals, :users, column: :user_id, on_delete: :cascade, reverse_lock_order: true
    )
    add_concurrent_index :targeted_message_dismissals, :user_id, name: INDEX_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :targeted_message_dismissals, column: :user_id, reverse_lock_order: true
    end

    remove_concurrent_index_by_name :targeted_message_dismissals, INDEX_NAME
  end
end
