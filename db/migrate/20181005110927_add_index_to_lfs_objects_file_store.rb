# frozen_string_literal: true

class AddIndexToLfsObjectsFileStore < ActiveRecord::Migration[4.2]
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
