# rubocop:disable RemoveIndex
class AddIndexesToMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:sync_time]
    add_concurrent_index :remote_mirrors, [:sync_time]
  end

  def down
    remove_index :projects, [:sync_time] if index_exists? :projects, [:sync_time]
    remove_index :remote_mirrors, [:sync_time] if index_exists? :remote_mirrors, [:sync_time]
  end
end
