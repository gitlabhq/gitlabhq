# frozen_string_literal: true

class AsyncValidateForeignKeyForCiPipelinesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_pipelines
  COLUMN_NAME = :auto_canceled_by_id_convert_to_bigint
  FK_NAME = :fk_67e4288f3a

  def up
    prepare_async_foreign_key_validation TABLE_NAME, COLUMN_NAME, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation TABLE_NAME, COLUMN_NAME, name: FK_NAME
  end
end
