# frozen_string_literal: true

class ReplaceOldFkCiBuildPendingStatesToBuildsV2 < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return if new_foreign_key_exists?

    with_lock_retries do
      remove_foreign_key_if_exists :ci_build_pending_states, :ci_builds,
        name: :fk_861cd17da3_p, reverse_lock_order: true

      rename_constraint :ci_build_pending_states, :temp_fk_861cd17da3_p, :fk_861cd17da3_p
    end
  end

  def down
    return unless new_foreign_key_exists?

    add_concurrent_foreign_key :ci_build_pending_states, :ci_builds,
      name: :temp_fk_861cd17da3_p,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true

    switch_constraint_names :ci_build_pending_states, :fk_861cd17da3_p, :temp_fk_861cd17da3_p
  end

  private

  def new_foreign_key_exists?
    foreign_key_exists?(:ci_build_pending_states, :p_ci_builds, name: :fk_861cd17da3_p)
  end
end
