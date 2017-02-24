class AddIndexToMirrorsLastUpdateAtFields < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :projects, :mirror_last_successful_update_at
    add_concurrent_index :remote_mirrors, :last_successful_update_at
  end
end
