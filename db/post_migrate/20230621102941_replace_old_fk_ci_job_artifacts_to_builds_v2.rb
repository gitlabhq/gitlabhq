# frozen_string_literal: true

class ReplaceOldFkCiJobArtifactsToBuildsV2 < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return if new_foreign_key_exists?

    with_lock_retries do
      remove_foreign_key_if_exists :ci_job_artifacts, :ci_builds,
        name: :fk_rails_c5137cb2c1_p, reverse_lock_order: true

      rename_constraint :ci_job_artifacts, :temp_fk_rails_c5137cb2c1_p, :fk_rails_c5137cb2c1_p
    end
  end

  def down
    return unless new_foreign_key_exists?

    add_concurrent_foreign_key :ci_job_artifacts, :ci_builds,
      name: :temp_fk_rails_c5137cb2c1_p,
      column: [:partition_id, :job_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true

    switch_constraint_names :ci_job_artifacts, :fk_rails_c5137cb2c1_p, :temp_fk_rails_c5137cb2c1_p
  end

  private

  def new_foreign_key_exists?
    foreign_key_exists?(:ci_job_artifacts, :p_ci_builds, name: :fk_rails_c5137cb2c1_p)
  end
end
