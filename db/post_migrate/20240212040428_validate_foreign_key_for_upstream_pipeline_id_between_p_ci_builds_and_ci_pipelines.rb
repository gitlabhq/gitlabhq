# frozen_string_literal: true

class ValidateForeignKeyForUpstreamPipelineIdBetweenPCiBuildsAndCiPipelines < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.10'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds
  TARGET_TABLE_NAME = :ci_pipelines
  COLUMN = :upstream_pipeline_id_convert_to_bigint
  TARGET_COLUMN = :id
  FK_NAME = :fk_6b6c3f3e70

  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      column: [COLUMN],
      target_column: [TARGET_COLUMN],
      reverse_lock_order: true,
      on_delete: :cascade,
      name: FK_NAME
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end

    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      column: [COLUMN],
      target_column: [TARGET_COLUMN],
      validate: false,
      reverse_lock_order: true,
      on_delete: :cascade,
      name: FK_NAME
    )
  end
end
