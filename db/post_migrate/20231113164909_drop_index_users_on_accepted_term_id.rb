# frozen_string_literal: true

class DropIndexUsersOnAcceptedTermId < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  TABLE_NAME = 'users'
  INDEX_NAME = 'index_users_on_accepted_term_id'
  COLUMN = 'accepted_term_id'

  def up
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, COLUMN, name: INDEX_NAME
  end
end
