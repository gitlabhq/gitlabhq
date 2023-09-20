# frozen_string_literal: true

class SyncIndexForCiPipelinesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines
  INDEX_NAME = 'index_ci_pipelines_on_auto_canceled_by_id_bigint'
  COLUMN_NAME = :auto_canceled_by_id_convert_to_bigint

  def up
    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
