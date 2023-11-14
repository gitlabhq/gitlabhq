# frozen_string_literal: true

class ChangeUnconfirmedCreatedAtIndexOnUsers < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_users_on_unconfirmed_and_created_at_for_active_humans'
  NEW_INDEX_NAME = 'index_users_on_unconfirmed_created_at_active_type_sign_in_count'

  def up
    # rubocop:disable Migration/PreventIndexCreation
    add_concurrent_index :users, [:created_at, :id],
      name: NEW_INDEX_NAME,
      where: "confirmed_at IS NULL AND state = 'active' AND user_type IN (0) AND sign_in_count = 0"
    # rubocop:enable Migration/PreventIndexCreation

    remove_concurrent_index_by_name :users, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :users, [:created_at, :id],
      name: OLD_INDEX_NAME,
      where: "confirmed_at IS NULL AND state = 'active' AND user_type IN (0)"

    remove_concurrent_index_by_name :users, NEW_INDEX_NAME
  end
end
