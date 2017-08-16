class AddIndexOnCiRunnersAccessLevel < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_runners, :access_level
  end

  def down
    remove_concurrent_index :ci_runners, :access_level if index_exists?(:ci_runners, :access_level)
  end
end
