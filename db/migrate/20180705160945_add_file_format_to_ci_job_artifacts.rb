class AddFileFormatToCiJobArtifacts < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :ci_job_artifacts, :file_format, :integer, limit: 2
  end
end
