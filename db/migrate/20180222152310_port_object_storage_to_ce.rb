# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PortObjectStorageToCe < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def add_column_idempotent(table, column, *defs)
    return if column_exists?(table, column)

    add_column(table, column, *defs)
  end

  def remove_column_idempotent(table, column)
    return unless column_exists?(table, column)

    remove_column(table, column)
  end

  def up
    add_column_idempotent(:ci_job_artifacts, :file_store, :integer)
    add_column_idempotent(:ci_builds, :artifacts_file_store, :integer)
    add_column_idempotent(:ci_builds, :artifacts_metadata_store, :integer)
    add_column_idempotent(:lfs_objects, :file_store, :integer)
    add_column_idempotent(:uploads, :store, :integer)
  end

  def down
    remove_column_idempotent(:ci_job_artifacts, :file_store)
    remove_column_idempotent(:ci_builds, :artifacts_file_store)
    remove_column_idempotent(:ci_builds, :artifacts_metadata_store)
    remove_column_idempotent(:lfs_objects, :file_store)
    remove_column_idempotent(:uploads, :store)
  end
end
