class AddChecksumToCiJobArtifacts < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :ci_job_artifacts, :file_sha256, :binary
  end
end
