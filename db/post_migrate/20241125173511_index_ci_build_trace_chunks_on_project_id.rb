# frozen_string_literal: true

class IndexCiBuildTraceChunksOnProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  TABLE_NAME = :ci_build_trace_chunks
  INDEX_NAME = :index_ci_build_trace_chunks_on_project_id

  def up
    add_concurrent_index TABLE_NAME, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
