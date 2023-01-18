# frozen_string_literal: true

class AddUserIndexAndFkToSshSignatures < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ssh_signatures_on_user_id'

  def up
    add_concurrent_index :ssh_signatures, :user_id, name: INDEX_NAME
    add_concurrent_foreign_key :ssh_signatures, :users, column: :user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ssh_signatures, column: :user_id
    end

    remove_concurrent_index_by_name :ssh_signatures, INDEX_NAME
  end
end
