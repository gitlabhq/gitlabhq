# frozen_string_literal: true

class ScheduleIndexRemovalCiBuildTraceMetadata < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!

  INDEX_NAME = :index_ci_build_trace_metadata_on_trace_artifact_id
  TABLE_NAME = :ci_build_trace_metadata
  COLUMN_NAME = :trace_artifact_id

  def up
    prepare_async_index_removal(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME)
  end
end
