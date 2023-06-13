# frozen_string_literal: true

class AddUnconfirmedCreatedAtIndexToUsers < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_users_on_unconfirmed_and_created_at_for_active_humans'

  def up
    add_concurrent_index :users, [:created_at, :id],
      name: INDEX_NAME,
      where: "confirmed_at IS NULL AND state = 'active' AND user_type IN (0)"
  end

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME
  end
end
