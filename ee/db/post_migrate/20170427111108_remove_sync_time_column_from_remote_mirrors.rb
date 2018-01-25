class RemoveSyncTimeColumnFromRemoteMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :remote_mirrors, [:sync_time] if index_exists? :remote_mirrors, [:sync_time]
    remove_column :remote_mirrors, :sync_time, :integer
  end

  def down
    add_column :remote_mirrors, :sync_time, :integer
    add_concurrent_index :remote_mirrors, [:sync_time]
  end
end
