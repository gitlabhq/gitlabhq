# frozen_string_literal: true

class PrepareAsyncIndexesForMergeRequestsHeadPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  TABLE_NAME = :merge_requests
  INDEX_NAME = :index_merge_requests_on_head_pipeline_id_bigint
  COLUMN_NAME = :head_pipeline_id_convert_to_bigint

  def up
    prepare_async_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end
end
