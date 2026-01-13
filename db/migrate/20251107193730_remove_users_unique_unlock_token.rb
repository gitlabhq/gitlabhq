# frozen_string_literal: true

class RemoveUsersUniqueUnlockToken < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  INDEX_NAME = 'index_users_on_unlock_token'

  def up
    remove_concurrent_index :users, :unlock_token, name: INDEX_NAME
  end

  def down
    add_concurrent_index :users, :unlock_token, unique: true, name: INDEX_NAME
  end
end
