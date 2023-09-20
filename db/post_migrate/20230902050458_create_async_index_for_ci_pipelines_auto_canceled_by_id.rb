# frozen_string_literal: true

class CreateAsyncIndexForCiPipelinesAutoCanceledById < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_pipelines
  INDEX_NAME = 'index_ci_pipelines_on_auto_canceled_by_id_bigint'
  COLUMN_NAME = :auto_canceled_by_id_convert_to_bigint

  def up
    prepare_async_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end
end
