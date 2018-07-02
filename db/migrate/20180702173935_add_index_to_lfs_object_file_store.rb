class AddIndexToLfsObjectFileStore < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :lfs_objects, :file_store
  end

  def down
    remove_concurrent_index :lfs_objects, :file_store
  end
end
