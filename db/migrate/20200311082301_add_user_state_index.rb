# frozen_string_literal: true

class AddUserStateIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:users, [:state, :user_type], where: 'ghost IS NOT TRUE', name: 'index_users_on_state_and_user_type_internal')
    remove_concurrent_index_by_name(:users, 'index_users_on_state_and_internal_ee')
    remove_concurrent_index_by_name(:users, 'index_users_on_state_and_internal')
  end

  def down
    add_concurrent_index(:users, :state, where: 'ghost IS NOT TRUE AND bot_type IS NULL', name: 'index_users_on_state_and_internal_ee')
    add_concurrent_index(:users, :state, where: 'ghost IS NOT TRUE', name: 'index_users_on_state_and_internal')
    remove_concurrent_index_by_name(:users, 'index_users_on_state_and_internal_ee')
  end
end
