# frozen_string_literal: true

class ChangeIndexUsersOnPublicEmail < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_users_on_public_email'
  INDEX_EXCLUDING_NULL_NAME = 'index_users_on_public_email_excluding_null_and_empty'

  disable_ddl_transaction!

  def up
    index_condition = "public_email != '' AND public_email IS NOT NULL"

    add_concurrent_index :users, [:public_email], where: index_condition, name: INDEX_EXCLUDING_NULL_NAME
    remove_concurrent_index_by_name :users, INDEX_NAME
  end

  def down
    index_condition = "public_email != ''"

    add_concurrent_index :users, [:public_email], where: index_condition, name: INDEX_NAME
    remove_concurrent_index_by_name :users, INDEX_EXCLUDING_NULL_NAME
  end
end
