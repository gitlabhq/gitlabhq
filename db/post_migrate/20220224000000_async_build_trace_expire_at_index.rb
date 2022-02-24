# frozen_string_literal: true

class AsyncBuildTraceExpireAtIndex < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'tmp_index_ci_job_artifacts_on_id_where_trace_and_expire_at'
  TIMESTAMPS = "'2021-04-22 00:00:00', '2021-05-22 00:00:00', '2021-06-22 00:00:00', '2022-01-22 00:00:00', '2022-02-22 00:00:00', '2022-03-22 00:00:00', '2022-04-22 00:00:00'"

  def up
    prepare_async_index :ci_job_artifacts, :id, where: "file_type = 3 AND expire_at IN (#{TIMESTAMPS})", name: INDEX_NAME
  end

  def down
    unprepare_async_index :ci_builds, :id, name: INDEX_NAME
  end
end
