class AddChecksumToCiJobArtifacts < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :ci_job_artifacts, :checksum, :string, limit: 64
  end
end

