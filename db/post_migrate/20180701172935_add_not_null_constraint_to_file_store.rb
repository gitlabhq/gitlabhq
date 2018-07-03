class AddNotNullConstraintToFileStore < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    change_column_null :ci_job_artifacts, :file_store, false
    change_column_null :lfs_objects, :file_store, false
    change_column_null :uploads, :store, false
  end

  def down
    change_column_null :ci_job_artifacts, :file_store, true
    change_column_null :lfs_objects, :file_store, true
    change_column_null :uploads, :store, true
  end
end
