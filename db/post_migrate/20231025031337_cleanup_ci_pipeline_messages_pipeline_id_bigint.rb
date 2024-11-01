# frozen_string_literal: true

class CleanupCiPipelineMessagesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE = :ci_pipeline_messages
  COLUMNS = [:pipeline_id]

  def up
    with_lock_retries(raise_on_exhaustion: true) do
      lock_tables(:ci_pipelines, TABLE)
      cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
    end
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)

    add_concurrent_index(
      TABLE, :pipeline_id_convert_to_bigint,
      name: :index_ci_pipeline_messages_on_pipeline_id_convert_to_bigint
    )
    add_concurrent_foreign_key(
      TABLE, :ci_pipelines,
      column: :pipeline_id_convert_to_bigint,
      on_delete: :cascade, validate: true, reverse_lock_order: true
    )
  end
end
