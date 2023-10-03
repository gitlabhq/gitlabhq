# frozen_string_literal: true

class SyncForeignKeyForCiPipelinesAutoCanceledByIdBigint < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_pipelines
  COLUMN_NAME = :auto_canceled_by_id_convert_to_bigint
  FK_NAME = :fk_67e4288f3a

  def up
    validate_foreign_key TABLE_NAME, COLUMN_NAME, name: FK_NAME
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
