# frozen_string_literal: true

class PrepareJobArtifactProjectIdIndex < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_ci_job_artifacts_on_project_id_and_id'

  def up
    prepare_async_index :ci_job_artifacts, [:project_id, :id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :notes, [:project_id, :id], name: INDEX_NAME
  end
end
