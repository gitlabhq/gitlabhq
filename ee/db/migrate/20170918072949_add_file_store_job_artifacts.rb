class AddFileStoreJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!
  DOWNTIME = false

  def up
    unless column_exists?(:ci_job_artifacts, :file_store)
      add_column(:ci_job_artifacts, :file_store, :integer)
    end
  end

  def down
    if column_exists?(:ci_job_artifacts, :file_store)
      remove_column(:ci_job_artifacts, :file_store)
    end
  end
end
