# frozen_string_literal: true

class FullyRemoveTemporaryJobTraceIndex < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_ci_job_artifacts_on_id_where_trace_and_expire_at'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :ci_job_artifacts, name: INDEX_NAME
  end

  def down
    add_concurrent_index :ci_job_artifacts, :id, name: INDEX_NAME
  end
end
