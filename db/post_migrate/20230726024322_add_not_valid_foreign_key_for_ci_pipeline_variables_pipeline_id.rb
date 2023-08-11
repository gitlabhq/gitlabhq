# frozen_string_literal: true

class AddNotValidForeignKeyForCiPipelineVariablesPipelineId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  SOURCE_TABLE = :ci_pipeline_variables
  TARGET_TABLE = :ci_pipelines
  COLUMN_NAME = :pipeline_id_convert_to_bigint
  FK_NAME = 'temp_fk_rails_8d3b04e3e1'

  def up
    add_concurrent_foreign_key(
      SOURCE_TABLE, TARGET_TABLE,
      name: FK_NAME,
      column: COLUMN_NAME,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true
    )

    prepare_async_foreign_key_validation SOURCE_TABLE, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation SOURCE_TABLE, name: FK_NAME

    remove_foreign_key_if_exists SOURCE_TABLE, name: FK_NAME
  end
end
