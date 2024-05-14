# frozen_string_literal: true

class RemovePCiJobArtifactsProjectIdIdx < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.11'

  def up
    prepare_async_index_removal :p_ci_job_artifacts, :project_id, name: 'p_ci_job_artifacts_project_id_idx'
  end

  def down
    unprepare_async_index :p_ci_job_artifacts, :project_id, name: 'p_ci_job_artifacts_project_id_idx'
  end
end
