# frozen_string_literal: true

class CleanupCiSourcesPipelinesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE = :ci_sources_pipelines
  REFERENCING_TABLE = :ci_pipelines
  COLUMNS = [:pipeline_id, :source_pipeline_id]

  def up
    with_lock_retries(raise_on_exhaustion: true) do
      lock_tables(:ci_pipelines, TABLE)
      cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
    end
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)

    add_concurrent_index(TABLE, :pipeline_id_convert_to_bigint,
      name: :index_ci_sources_pipelines_on_pipeline_id_bigint)
    add_concurrent_index(TABLE, :source_pipeline_id_convert_to_bigint,
      name: :index_ci_sources_pipelines_on_source_pipeline_id_bigint)
    add_concurrent_foreign_key(
      TABLE, REFERENCING_TABLE,
      column: :pipeline_id_convert_to_bigint,
      on_delete: :cascade, validate: true, reverse_lock_order: true
    )
    add_concurrent_foreign_key(
      TABLE, REFERENCING_TABLE,
      column: :source_pipeline_id_convert_to_bigint,
      on_delete: :cascade, validate: true, reverse_lock_order: true
    )
  end
end
