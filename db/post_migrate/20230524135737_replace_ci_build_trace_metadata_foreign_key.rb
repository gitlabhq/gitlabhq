# frozen_string_literal: true

class ReplaceCiBuildTraceMetadataForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_build_trace_metadata, :p_ci_builds,
      name: 'temp_fk_rails_aebc78111f_p',
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true

    prepare_async_foreign_key_validation :ci_build_trace_metadata,
      name: 'temp_fk_rails_aebc78111f_p'
  end

  def down
    unprepare_async_foreign_key_validation :ci_build_trace_metadata, name: 'temp_fk_rails_aebc78111f_p'
    remove_foreign_key :ci_build_trace_metadata, name: 'temp_fk_rails_aebc78111f_p'
  end
end
