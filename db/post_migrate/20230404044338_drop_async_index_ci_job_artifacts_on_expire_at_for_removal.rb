# frozen_string_literal: true

class DropAsyncIndexCiJobArtifactsOnExpireAtForRemoval < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_ci_job_artifacts_on_expire_at_for_removal'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/393913
  def up
    prepare_async_index_removal :ci_job_artifacts, :expire_at, name: INDEX_NAME
  end

  def down
    unprepare_async_index :ci_job_artifacts, :expire_at, name: INDEX_NAME
  end
end
