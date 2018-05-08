class RemoveSyncTimeColumnFromRemoteMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :remote_mirrors, [:sync_time] if index_exists? :remote_mirrors, [:sync_time]
    remove_column :remote_mirrors, :sync_time, :integer if column_exists? :remote_mirrors, :sync_time
  end

  def down
    add_column :remote_mirrors, :sync_time, :integer unless column_exists? :remote_mirrors, :sync_time
    add_concurrent_index :remote_mirrors, [:sync_time] unless index_exists? :remote_mirrors, [:sync_time]
  end
end
