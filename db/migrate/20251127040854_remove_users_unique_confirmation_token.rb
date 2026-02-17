# frozen_string_literal: true

class RemoveUsersUniqueConfirmationToken < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  INDEX_NAME = 'index_users_on_confirmation_token'

  def up
    remove_concurrent_index :users, :confirmation_token, name: INDEX_NAME
  end

  def down
    add_concurrent_index :users, :confirmation_token, unique: true, name: INDEX_NAME
  end
end
