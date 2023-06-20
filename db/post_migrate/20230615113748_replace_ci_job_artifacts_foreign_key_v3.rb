# frozen_string_literal: true

class ReplaceCiJobArtifactsForeignKeyV3 < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_job_artifacts, :p_ci_builds,
      name: 'temp_fk_rails_c5137cb2c1_p',
      column: [:partition_id, :job_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true
  end

  def down
    remove_foreign_key_if_exists :ci_job_artifacts, name: 'temp_fk_rails_c5137cb2c1_p'
  end
end
