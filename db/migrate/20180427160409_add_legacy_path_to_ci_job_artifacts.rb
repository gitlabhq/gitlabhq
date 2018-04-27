class AddLegacyPathToCiJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_job_artifacts, :path_type, :integer
  end
end
