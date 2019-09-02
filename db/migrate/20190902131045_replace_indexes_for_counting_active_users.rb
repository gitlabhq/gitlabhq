# frozen_string_literal: true

class ReplaceIndexesForCountingActiveUsers < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:users, 'index_users_on_state_and_internal')

    add_concurrent_index(:users, :state, where: 'ghost IS NOT TRUE', name: 'index_users_on_state_and_internal')
    add_concurrent_index(:users, :state, where: 'ghost IS NOT TRUE AND bot_type IS NULL', name: 'index_users_on_state_and_internal_ee')
  end

  def down
    remove_concurrent_index_by_name(:users, 'index_users_on_state_and_internal_ee')
    remove_concurrent_index_by_name(:users, 'index_users_on_state_and_internal')

    add_concurrent_index(:users, :state, where: 'ghost <> true AND bot_type IS NULL', name: 'index_users_on_state_and_internal')
  end
end
