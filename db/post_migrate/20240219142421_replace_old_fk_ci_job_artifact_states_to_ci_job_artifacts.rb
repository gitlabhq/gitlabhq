# frozen_string_literal: true

class ReplaceOldFkCiJobArtifactStatesToCiJobArtifacts < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  TABLE_NAME = :ci_job_artifact_states
  REFERENCED_TABLE_NAME = :ci_job_artifacts
  FK_NAME = :fk_rails_80a9cba3b2_p
  TMP_FK_NAME = :tmp_fk_rails_80a9cba3b2_p

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(TABLE_NAME, REFERENCED_TABLE_NAME, name: FK_NAME, reverse_lock_order: true)
      rename_constraint(TABLE_NAME, TMP_FK_NAME, FK_NAME)
    end
  end

  def down
    add_concurrent_foreign_key(TABLE_NAME,
      REFERENCED_TABLE_NAME,
      name: TMP_FK_NAME,
      column: [:partition_id, :job_artifact_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true
    )

    switch_constraint_names(TABLE_NAME, FK_NAME, TMP_FK_NAME)
  end
end
