# rubocop:disable Migration/UpdateLargeTable
class AddSyncScheduleToProjectsAndRemoteProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:remote_mirrors, :sync_time, :integer, default: 60)
    add_column_with_default(:projects, :sync_time, :integer, default: 60)
  end

  def down
    remove_column :projects, :sync_time
    remove_column :remote_mirrors, :sync_time
  end
end
