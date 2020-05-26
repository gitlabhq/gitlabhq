# frozen_string_literal: true

class RenameUserTypeIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :users, [:state, :user_type], name: 'index_users_on_state_and_user_type'
    remove_concurrent_index_by_name :users, 'index_users_on_state_and_user_type_internal'
  end

  def down
    add_concurrent_index :users, [:state, :user_type], where: 'ghost IS NOT TRUE', name: 'index_users_on_state_and_user_type_internal'
    remove_concurrent_index_by_name :users, 'index_users_on_state_and_user_type'
  end
end
