# frozen_string_literal: true

class ReplaceCiBuildTraceChunksForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_build_trace_chunks, :p_ci_builds,
      name: 'temp_fk_89e29fa5ee_p',
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true

    prepare_async_foreign_key_validation :ci_build_trace_chunks,
      name: 'temp_fk_89e29fa5ee_p'
  end

  def down
    unprepare_async_foreign_key_validation :ci_build_trace_chunks, name: 'temp_fk_89e29fa5ee_p'
    remove_foreign_key :ci_build_trace_chunks, name: 'temp_fk_89e29fa5ee_p'
  end
end
