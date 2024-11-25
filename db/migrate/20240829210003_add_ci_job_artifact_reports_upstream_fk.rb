# frozen_string_literal: true

class AddCiJobArtifactReportsUpstreamFk < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '17.6'
  disable_ddl_transaction!

  FK_NAME = :fk_rails_f9b8550174
  SOURCE_TABLE_NAME = :p_ci_job_artifact_reports
  TARGET_TABLE_NAME = :p_ci_job_artifacts

  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      column: [:partition_id, :job_artifact_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: FK_NAME
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end
end
