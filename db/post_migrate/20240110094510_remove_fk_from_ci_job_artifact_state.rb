# frozen_string_literal: true

class RemoveFkFromCiJobArtifactState < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_job_artifact_states
  TARGET_TABLE_NAME = :ci_job_artifacts
  COLUMN = :job_artifact_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_rails_80a9cba3b2

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: COLUMN,
      target_column: TARGET_COLUMN,
      validate: true,
      reverse_lock_order: true,
      on_delete: :cascade,
      name: FK_NAME
    )
  end
end
