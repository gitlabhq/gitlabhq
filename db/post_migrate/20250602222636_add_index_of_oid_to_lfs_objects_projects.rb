# frozen_string_literal: true

class AddIndexOfOidToLfsObjectsProjects < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.1'

  INDEX_NAME = 'index_lfs_objects_projects_on_oid'

  def up
    add_concurrent_index :lfs_objects_projects, :oid, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :lfs_objects_projects, :oid, name: INDEX_NAME
  end
end
