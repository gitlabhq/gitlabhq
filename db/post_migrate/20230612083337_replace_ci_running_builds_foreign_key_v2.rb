# frozen_string_literal: true

class ReplaceCiRunningBuildsForeignKeyV2 < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!

  def up
    return unless should_run?

    add_concurrent_foreign_key :ci_running_builds, :p_ci_builds,
      name: 'temp_fk_rails_da45cfa165_p',
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true

    prepare_async_foreign_key_validation :ci_running_builds,
      name: 'temp_fk_rails_da45cfa165_p'
  end

  def down
    return unless should_run?

    unprepare_async_foreign_key_validation :ci_running_builds, name: 'temp_fk_rails_da45cfa165_p'
    remove_foreign_key_if_exists :ci_running_builds, name: 'temp_fk_rails_da45cfa165_p'
  end

  private

  def should_run?
    can_execute_on?(:ci_running_builds, :ci_builds)
  end
end
