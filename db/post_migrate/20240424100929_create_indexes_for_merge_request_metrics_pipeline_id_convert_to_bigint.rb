# frozen_string_literal: true

class CreateIndexesForMergeRequestMetricsPipelineIdConvertToBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'

  TABLE_NAME = :merge_request_metrics
  INDEX_NAME = :index_merge_request_metrics_on_pipeline_id_bigint
  COLUMN_NAME = :pipeline_id_convert_to_bigint

  def up
    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end
end
