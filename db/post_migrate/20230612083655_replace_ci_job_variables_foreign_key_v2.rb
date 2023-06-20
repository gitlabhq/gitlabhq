# frozen_string_literal: true

class ReplaceCiJobVariablesForeignKeyV2 < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!

  def up
    return unless should_run?

    add_concurrent_foreign_key :ci_job_variables, :p_ci_builds,
      name: 'temp_fk_rails_fbf3b34792_p',
      column: [:partition_id, :job_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true

    prepare_async_foreign_key_validation :ci_job_variables,
      name: 'temp_fk_rails_fbf3b34792_p'
  end

  def down
    return unless should_run?

    unprepare_async_foreign_key_validation :ci_job_variables, name: 'temp_fk_rails_fbf3b34792_p'
    remove_foreign_key_if_exists :ci_job_variables, name: 'temp_fk_rails_fbf3b34792_p'
  end

  private

  def should_run?
    can_execute_on?(:ci_job_variables, :ci_builds)
  end
end
