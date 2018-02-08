class AddDateIndexesToEpics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :epics, :start_date
    add_concurrent_index :epics, :end_date
  end

  def down
    remove_concurrent_index :epics, :start_date
    remove_concurrent_index :epics, :end_date
  end
end
