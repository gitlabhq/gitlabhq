# frozen_string_literal: true

class ReplaceOldFkCiSourcesPipelinesToBuildsV2 < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return if new_foreign_key_exists?

    with_lock_retries do
      remove_foreign_key_if_exists :ci_sources_pipelines, :ci_builds,
        name: :fk_be5624bf37_p, reverse_lock_order: true

      rename_constraint :ci_sources_pipelines, :temp_fk_be5624bf37_p, :fk_be5624bf37_p
    end
  end

  def down
    return unless new_foreign_key_exists?

    add_concurrent_foreign_key :ci_sources_pipelines, :ci_builds,
      name: :temp_fk_be5624bf37_p,
      column: [:source_partition_id, :source_job_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true

    switch_constraint_names :ci_sources_pipelines, :fk_be5624bf37_p, :temp_fk_be5624bf37_p
  end

  private

  def new_foreign_key_exists?
    foreign_key_exists?(:ci_sources_pipelines, :p_ci_builds, name: :fk_be5624bf37_p)
  end
end
