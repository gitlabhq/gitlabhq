# frozen_string_literal: true

class RenameCiJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    rename_table_with_view(
     :ci_job_artifacts,
     :ci_build_artifacts)
  end
end
