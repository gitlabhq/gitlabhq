# frozen_string_literal: true

class ReplaceCiJobArtifactsForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_job_artifacts, :p_ci_builds,
      name: 'temp_fk_rails_c5137cb2c1_p',
      column: [:partition_id, :job_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true

    prepare_async_foreign_key_validation :ci_job_artifacts,
      name: 'temp_fk_rails_c5137cb2c1_p'
  end

  def down
    unprepare_async_foreign_key_validation :ci_job_artifacts, name: 'temp_fk_rails_c5137cb2c1_p'
    remove_foreign_key :ci_job_artifacts, name: 'temp_fk_rails_c5137cb2c1_p'
  end
end
