class AddFileLocationToCiJobArtifacts < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_job_artifacts, :file_location, :integer, limit: 2
  end
end
