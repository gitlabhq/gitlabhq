class AddChecksumToCiJobArtifacts < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :ci_job_artifacts, :file_sha256, :binary
  end
end
