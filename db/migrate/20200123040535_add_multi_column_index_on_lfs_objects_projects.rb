# frozen_string_literal: true

class AddMultiColumnIndexOnLfsObjectsProjects < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :lfs_objects_projects, [:project_id, :lfs_object_id]
  end

  def down
    remove_concurrent_index :lfs_objects_projects, [:project_id, :lfs_object_id]
  end
end
