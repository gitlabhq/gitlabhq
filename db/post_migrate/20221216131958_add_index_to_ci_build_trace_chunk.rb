# frozen_string_literal: true

class AddIndexToCiBuildTraceChunk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = :index_ci_build_trace_chunks_on_partition_id_build_id
  TABLE_NAME = :ci_build_trace_chunks
  COLUMNS = [:partition_id, :build_id]

  def up
    add_concurrent_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
