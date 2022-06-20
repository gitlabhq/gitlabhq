# frozen_string_literal: true

class AddJobArtifactIdOnRefreshStartToBuildArtifactsSizeRefresh < Gitlab::Database::Migration[2.0]
  def change
    add_column :project_build_artifacts_size_refreshes, :last_job_artifact_id_on_refresh_start, :bigint, default: 0
  end
end
