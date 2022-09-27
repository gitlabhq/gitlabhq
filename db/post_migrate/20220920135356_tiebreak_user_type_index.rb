# frozen_string_literal: true

class TiebreakUserTypeIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_users_on_user_type_and_id'
  OLD_INDEX_NAME = 'index_users_on_user_type'

  def up
    add_concurrent_index :users, [:user_type, :id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :users, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :users, :user_type, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :users, NEW_INDEX_NAME
  end
end
