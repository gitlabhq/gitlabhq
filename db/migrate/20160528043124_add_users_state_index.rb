# rubocop:disable all
class AddUsersStateIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def change
    add_concurrent_index :users, :state
  end
end
