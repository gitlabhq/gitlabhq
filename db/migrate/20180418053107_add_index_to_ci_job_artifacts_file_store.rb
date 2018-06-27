class AddIndexToCiJobArtifactsFileStore < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_job_artifacts, :file_store
  end

  def down
    remove_index :ci_job_artifacts, :file_store if index_exists?(:ci_job_artifacts, :file_store)
  end
end
