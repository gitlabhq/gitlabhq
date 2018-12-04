class AddFileStoreJobArtifacts < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!
  DOWNTIME = false

  def change
    add_column(:ci_job_artifacts, :file_store, :integer)
  end
end
