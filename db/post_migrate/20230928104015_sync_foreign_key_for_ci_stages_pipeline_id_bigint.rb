# frozen_string_literal: true

class SyncForeignKeyForCiStagesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_stages
  COLUMN_NAME = :pipeline_id_convert_to_bigint
  FK_NAME = :fk_c5ddde695f

  def up
    validate_foreign_key TABLE_NAME, COLUMN_NAME, name: FK_NAME
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
