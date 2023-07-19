# frozen_string_literal: true

class ReplaceCiJobVariablesForeignKeyV3 < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_job_variables, :p_ci_builds,
      name: 'temp_fk_rails_fbf3b34792_p',
      column: [:partition_id, :job_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true
  end

  def down
    remove_foreign_key_if_exists :ci_job_variables, name: 'temp_fk_rails_fbf3b34792_p'
  end
end
