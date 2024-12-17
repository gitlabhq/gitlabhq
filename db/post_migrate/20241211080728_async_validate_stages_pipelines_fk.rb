# frozen_string_literal: true

class AsyncValidateStagesPipelinesFk < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.7'

  SOURCE_TABLE_NAME = :p_ci_stages
  TARGET_TABLE_NAME = :p_ci_pipelines
  COLUMN = :pipeline_id
  TARGET_COLUMN = :id
  PARTITION_COLUMN = :partition_id
  FK_NAME = :fk_rails_5d4d96d44b_p

  def up
    return unless Gitlab.com_except_jh?

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

    prepare_partitioned_async_foreign_key_validation(SOURCE_TABLE_NAME, name: FK_NAME)
  end

  def down
    return unless Gitlab.com_except_jh?

    unprepare_partitioned_async_foreign_key_validation(SOURCE_TABLE_NAME, name: FK_NAME)
  end
end
