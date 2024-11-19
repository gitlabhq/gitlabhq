# frozen_string_literal: true

class AddIndexToCiBuildTraceMetadata < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!
  INDEX_NAME = :index_ci_build_trace_metadata_on_trace_artifact_id_partition_id
  TABLE_NAME = :ci_build_trace_metadata

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index(TABLE_NAME, [:trace_artifact_id, :partition_id], name: INDEX_NAME)
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
