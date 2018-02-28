class AddChecksumToCiJobArtifacts < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :ci_job_artifacts, :checksum, :binary
  end
end
