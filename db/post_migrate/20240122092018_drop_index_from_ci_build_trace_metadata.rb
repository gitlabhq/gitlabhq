# frozen_string_literal: true

class DropIndexFromCiBuildTraceMetadata < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  disable_ddl_transaction!

  INDEX_NAME = :index_ci_build_trace_metadata_on_trace_artifact_id
  TABLE_NAME = :ci_build_trace_metadata

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :trace_artifact_id, name: INDEX_NAME)
  end
end
