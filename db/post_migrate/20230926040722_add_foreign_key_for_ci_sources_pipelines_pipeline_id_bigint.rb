# frozen_string_literal: true

class AddForeignKeyForCiSourcesPipelinesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_sources_pipelines
  REFERENCING_TABLE_NAME = :ci_pipelines
  COLUMN_NAMES = [:pipeline_id_convert_to_bigint, :source_pipeline_id_convert_to_bigint]

  disable_ddl_transaction!

  def up
    COLUMN_NAMES.each do |column_name|
      add_concurrent_foreign_key(
        TABLE_NAME, REFERENCING_TABLE_NAME,
        column: column_name, on_delete: :cascade, validate: false, reverse_lock_order: true
      )
    end
  end

  def down
    COLUMN_NAMES.each do |column_name|
      with_lock_retries do
        remove_foreign_key_if_exists TABLE_NAME, column: column_name
      end
    end
  end
end
