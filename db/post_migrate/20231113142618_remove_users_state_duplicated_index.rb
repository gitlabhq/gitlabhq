# frozen_string_literal: true

class RemoveUsersStateDuplicatedIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = :index_users_on_state
  TABLE_NAME = :users

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :state, name: INDEX_NAME
  end
end
