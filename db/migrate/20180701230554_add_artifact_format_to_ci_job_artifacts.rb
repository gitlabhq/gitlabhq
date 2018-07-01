class AddArtifactFormatToCiJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_job_artifacts, :artifact_format, :integer, limit: 2
  end
end
