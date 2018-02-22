# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PortObjectStorageToCe < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    unless column_exists?(:ci_job_artifacts, :file_store)
      add_column(:ci_job_artifacts, :file_store, :integer)
    end

    unless column_exists?(:lfs_objects, :file_store)
      add_column(:lfs_objects, :file_store, :integer)
    end

    unless column_exists?(:uploads, :store)
      add_column(:uploads, :store, :integer)
    end
  end

  def down
    if column_exists?(:ci_job_artifacts, :file_store)
      remove_column(:ci_job_artifacts, :file_store)
    end

    if column_exists?(:lfs_objects, :file_store)
      remove_column(:lfs_objects, :file_store)
    end

    if column_exists?(:uploads, :store)
      remove_column(:uploads, :store)
    end
  end
end
