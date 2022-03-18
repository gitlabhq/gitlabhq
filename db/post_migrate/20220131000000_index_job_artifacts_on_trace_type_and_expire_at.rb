# frozen_string_literal: true

class IndexJobArtifactsOnTraceTypeAndExpireAt < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_ci_job_artifacts_on_id_where_trace_and_expire_at'
  TIMESTAMPS = "'2021-04-22 00:00:00', '2021-05-22 00:00:00', '2021-06-22 00:00:00', '2022-01-22 00:00:00', '2022-02-22 00:00:00', '2022-03-22 00:00:00', '2022-04-22 00:00:00'"

  def up
    add_concurrent_index :ci_job_artifacts, :id, where: "file_type = 3 AND expire_at IN (#{TIMESTAMPS})", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end
