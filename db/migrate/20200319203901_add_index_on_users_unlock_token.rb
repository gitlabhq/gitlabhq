# frozen_string_literal: true

class AddIndexOnUsersUnlockToken < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_users_on_unlock_token'

  disable_ddl_transaction!

  def up
    add_concurrent_index :users, :unlock_token, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :users, :unlock_token, unique: true, name: INDEX_NAME
  end
end
