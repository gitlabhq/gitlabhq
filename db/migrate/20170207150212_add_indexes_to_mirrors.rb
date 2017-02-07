class AddIndexesToMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :projects, [:sync_time]
    add_concurrent_index :remote_mirrors, [:sync_time]
  end
end
