# frozen_string_literal: true

class AddFkToCiSourcesPipelinesOnSourcePartitionIdAndSourceJobId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_sources_pipelines
  TARGET_TABLE_NAME = :ci_builds
  COLUMN = :source_job_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_be5624bf37_p
  PARTITION_COLUMN = :source_partition_id

  def up
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [:partition_id, TARGET_COLUMN],
      validate: false,
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
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
