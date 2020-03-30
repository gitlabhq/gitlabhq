# frozen_string_literal: true

class RemoveUsersSupportType < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_STATE_INTERNAL_ATTRS = 'index_users_on_state_and_internal_attrs'

  disable_ddl_transaction!

  def up
    remove_concurrent_index :users, :state, name: INDEX_STATE_INTERNAL_ATTRS
    remove_concurrent_index :users, :support_bot

    remove_column :users, :support_bot
  end

  def down
    add_column :users, :support_bot, :boolean # rubocop:disable Migration/AddColumnsToWideTables

    add_concurrent_index :users, :support_bot
    add_concurrent_index :users, :state,
      name: INDEX_STATE_INTERNAL_ATTRS,
      where: 'ghost <> true AND support_bot <> true'
  end
end
