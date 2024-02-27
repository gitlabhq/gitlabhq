# frozen_string_literal: true

class AddTempBackfillIndexToUsersOnIdForDarkThemeIds < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  INDEX_NAME = 'temp_index_on_users_where_dark_theme'

  def up
    add_concurrent_index :users, :id, name: INDEX_NAME, where: 'theme_id = 11' # rubocop:disable Migration/PreventIndexCreation -- Temporary index to backfill a column. The column will be moved off to user_pereferences later.
  end

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME
  end
end
