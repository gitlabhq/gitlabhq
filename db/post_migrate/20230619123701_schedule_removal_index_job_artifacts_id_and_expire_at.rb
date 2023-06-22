# frozen_string_literal: true

class ScheduleRemovalIndexJobArtifactsIdAndExpireAt < Gitlab::Database::Migration[2.1]
  INDEX_NAME = :tmp_index_ci_job_artifacts_on_id_expire_at_file_type_trace
  TABLE_NAME = :ci_job_artifacts
  COLUMN = :id

  # Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/368979
  def up
    prepare_async_index_removal(TABLE_NAME, COLUMN, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMN, name: INDEX_NAME)
  end
end
