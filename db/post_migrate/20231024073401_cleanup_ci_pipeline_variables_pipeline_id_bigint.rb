# frozen_string_literal: true

class CleanupCiPipelineVariablesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE = :ci_pipeline_variables
  REFERENCING_TABLE = :ci_pipelines
  COLUMNS = [:pipeline_id]
  INDEX_NAME = :index_ci_pipeline_variables_on_pipeline_id_bigint_and_key
  FK_NAME = :temp_fk_rails_8d3b04e3e1

  def up
    with_lock_retries(raise_on_exhaustion: true) do
      lock_tables(:ci_pipelines, TABLE)
      cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
    end
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)

    add_concurrent_index(
      TABLE, [:pipeline_id_convert_to_bigint, :key],
      name: INDEX_NAME, unique: true
    )
    add_concurrent_foreign_key(
      TABLE, REFERENCING_TABLE,
      column: :pipeline_id_convert_to_bigint, name: FK_NAME,
      on_delete: :cascade, validate: true, reverse_lock_order: true
    )
  end
end
