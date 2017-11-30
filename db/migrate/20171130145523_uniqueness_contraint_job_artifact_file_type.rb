class UniquenessContraintJobArtifactFileType < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_job_artifacts, [:job_id, :file_type], unique: true
  end

  def down
    remove_concurrent_index :ci_job_artifacts, [:job_id, :file_type]
  end
end
