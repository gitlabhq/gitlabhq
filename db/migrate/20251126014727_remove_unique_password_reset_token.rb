# frozen_string_literal: true

class RemoveUniquePasswordResetToken < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  INDEX_NAME = 'index_users_on_reset_password_token'

  def up
    remove_concurrent_index_by_name :users, name: INDEX_NAME
  end

  def down
    add_concurrent_index :users, :reset_password_token, unique: true, name: INDEX_NAME
  end
end
