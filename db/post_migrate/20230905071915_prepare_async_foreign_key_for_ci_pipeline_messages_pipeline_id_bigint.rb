# frozen_string_literal: true

class PrepareAsyncForeignKeyForCiPipelineMessagesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_pipeline_messages
  COLUMN_NAME = :pipeline_id_convert_to_bigint
  FK_NAME = :fk_0946fea681

  def up
    prepare_async_foreign_key_validation TABLE_NAME, COLUMN_NAME, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation TABLE_NAME, COLUMN_NAME, name: FK_NAME
  end
end
