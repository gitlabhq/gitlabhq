# frozen_string_literal: true

class ReplaceCiSourcesPipelinesForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_sources_pipelines, :p_ci_builds,
      name: 'temp_fk_be5624bf37_p',
      column: [:source_partition_id, :source_job_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true

    prepare_async_foreign_key_validation :ci_sources_pipelines,
      name: 'temp_fk_be5624bf37_p'
  end

  def down
    unprepare_async_foreign_key_validation :ci_sources_pipelines, name: 'temp_fk_be5624bf37_p'
    remove_foreign_key :ci_sources_pipelines, name: 'temp_fk_be5624bf37_p'
  end
end
