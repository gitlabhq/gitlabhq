# frozen_string_literal: true

class DropTemporaryJobTraceIndex < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_ci_job_artifacts_on_id_where_trace_and_expire_at'

  def up
    prepare_async_index_removal :ci_job_artifacts, :id, name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end
