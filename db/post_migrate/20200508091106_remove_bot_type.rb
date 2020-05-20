# frozen_string_literal: true

class RemoveBotType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :users, 'index_users_on_bot_type'

    with_lock_retries do
      remove_column :users, :bot_type
    end
  end

  def down
    unless column_exists?(:users, :bot_type)
      with_lock_retries do
        add_column :users, :bot_type, :integer, limit: 2 # rubocop:disable Migration/AddColumnsToWideTables
      end
    end

    execute 'UPDATE users set bot_type = user_type WHERE user_type IN(1,2,3,6)'

    add_concurrent_index :users, :bot_type
  end
end
