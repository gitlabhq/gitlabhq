# frozen_string_literal: true

class ReplaceCiJobArtifactStatesForeignKey < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  TABLE_NAME = :ci_job_artifact_states
  FK_NAME = :tmp_fk_rails_80a9cba3b2_p

  def up
    add_concurrent_foreign_key(
      TABLE_NAME,
      :p_ci_job_artifacts,
      name: FK_NAME,
      column: [:partition_id, :job_artifact_id],
      target_column: [:partition_id, :id],
      on_delete: :cascade,
      on_update: :cascade,
      validate: false,
      reverse_lock_order: true
    )

    prepare_async_foreign_key_validation(TABLE_NAME, name: FK_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, name: FK_NAME)
    remove_foreign_key_if_exists(TABLE_NAME, name: FK_NAME)
  end
end
