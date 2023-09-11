# frozen_string_literal: true

class AddForeignKeyForCiPipelineMessagesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_pipeline_messages
  REFERENCING_TABLE_NAME = :ci_pipelines
  COLUMN_NAME = :pipeline_id_convert_to_bigint

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      TABLE_NAME, REFERENCING_TABLE_NAME,
      column: COLUMN_NAME, on_delete: :cascade, validate: false, reverse_lock_order: true
    )
  end

  def down
    remove_foreign_key_if_exists TABLE_NAME, column: COLUMN_NAME
  end
end
