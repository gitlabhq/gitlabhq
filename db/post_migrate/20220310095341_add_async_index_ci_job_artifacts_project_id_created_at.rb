# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAsyncIndexCiJobArtifactsProjectIdCreatedAt < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_ci_job_artifacts_on_id_project_id_and_created_at'

  def up
    prepare_async_index :ci_job_artifacts, [:project_id, :created_at, :id], name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end
