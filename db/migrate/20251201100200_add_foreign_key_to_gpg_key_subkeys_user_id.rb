# frozen_string_literal: true

class AddForeignKeyToGpgKeySubkeysUserId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  def up
    add_concurrent_foreign_key :gpg_key_subkeys,
      :users,
      column: :user_id,
      reverse_lock_order: true,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :gpg_key_subkeys,
        column: :user_id,
        reverse_lock_order: true
    end
  end
end
