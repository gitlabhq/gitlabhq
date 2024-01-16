# frozen_string_literal: true

class AddFkToCiJobArtifactStatesOnPartitionIdAndJobArtifactId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '16.8'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_job_artifact_states
  TARGET_TABLE_NAME = :ci_job_artifacts
  COLUMN = :job_artifact_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_rails_80a9cba3b2_p
  PARTITION_COLUMN = :partition_id

  def up
    return unless should_run?

    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_COLUMN, TARGET_COLUMN],
      validate: false,
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      name: FK_NAME
    )

    prepare_async_foreign_key_validation(SOURCE_TABLE_NAME, name: FK_NAME)
  end

  def down
    return unless should_run?

    unprepare_async_foreign_key_validation(SOURCE_TABLE_NAME, name: FK_NAME)

    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end

  private

  def should_run?
    can_execute_on?(TARGET_TABLE_NAME)
  end
end
