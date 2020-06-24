# frozen_string_literal: true

class RemoveIndexLfsObjectsFileStoreIsNull < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_lfs_objects_file_store_is_null'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:lfs_objects, INDEX_NAME)
  end

  def down
    add_concurrent_index(:lfs_objects, :id, where: "file_store IS NULL", name: INDEX_NAME)
  end
end
