# frozen_string_literal: true

class DropUsersGhostColumn < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :users, 'index_users_on_ghost'

    with_lock_retries do
      remove_column :users, :ghost
    end
  end

  def down
    unless column_exists?(:users, :ghost)
      with_lock_retries do
        add_column :users, :ghost, :boolean # rubocop:disable Migration/AddColumnsToWideTables
      end
    end

    execute 'UPDATE users set ghost = TRUE WHERE user_type = 5'

    add_concurrent_index :users, :ghost
  end
end
