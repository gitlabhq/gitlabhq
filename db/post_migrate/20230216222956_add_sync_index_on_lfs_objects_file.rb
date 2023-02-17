# frozen_string_literal: true

class AddSyncIndexOnLfsObjectsFile < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_lfs_objects_on_file'

  disable_ddl_transaction!

  def up
    add_concurrent_index :lfs_objects, :file, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :lfs_objects, INDEX_NAME
  end
end
