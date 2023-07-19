# frozen_string_literal: true

class ReplaceOldFkCiRunningBuildsToBuilds < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!

  def up
    return unless should_run?
    return if new_foreign_key_exists?

    with_lock_retries do
      remove_foreign_key_if_exists :ci_running_builds, :ci_builds,
        name: :fk_rails_da45cfa165_p, reverse_lock_order: true

      rename_constraint :ci_running_builds, :temp_fk_rails_da45cfa165_p, :fk_rails_da45cfa165_p
    end
  end

  def down
    return unless should_run?
    return unless new_foreign_key_exists?

    add_concurrent_foreign_key :ci_running_builds, :ci_builds,
      name: :temp_fk_rails_da45cfa165_p,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true

    switch_constraint_names :ci_running_builds, :fk_rails_da45cfa165_p, :temp_fk_rails_da45cfa165_p
  end

  private

  def should_run?
    can_execute_on?(:ci_running_builds, :ci_builds)
  end

  def new_foreign_key_exists?
    foreign_key_exists?(:ci_running_builds, :p_ci_builds, name: :fk_rails_da45cfa165_p)
  end
end
