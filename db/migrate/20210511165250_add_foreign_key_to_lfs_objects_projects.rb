# frozen_string_literal: true

class AddForeignKeyToLfsObjectsProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :lfs_objects_projects, :lfs_objects, column: :lfs_object_id, on_delete: :restrict, validate: false
    add_concurrent_foreign_key :lfs_objects_projects, :projects, column: :project_id, on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key :lfs_objects_projects, column: :lfs_object_id
      remove_foreign_key :lfs_objects_projects, column: :project_id
    end
  end
end
