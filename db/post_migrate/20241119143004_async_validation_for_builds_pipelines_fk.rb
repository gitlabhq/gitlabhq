# frozen_string_literal: true

class AsyncValidationForBuildsPipelinesFk < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '17.7'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds
  TARGET_TABLE_NAME = :p_ci_pipelines
  COLUMN = :commit_id
  TARGET_COLUMN = :id
  PARTITION_COLUMN = :partition_id
  FK_NAME = :fk_rails_d739f46384_p

  def up
    add_concurrent_partitioned_foreign_key(
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

    prepare_partitioned_async_foreign_key_validation SOURCE_TABLE_NAME, name: FK_NAME
  end

  def down
    unprepare_partitioned_async_foreign_key_validation SOURCE_TABLE_NAME, name: FK_NAME
  end
end
