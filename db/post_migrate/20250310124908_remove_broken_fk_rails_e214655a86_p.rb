# frozen_string_literal: true

class RemoveBrokenFkRailsE214655a86P < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '17.11'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds_execution_configs
  TARGET_TABLE_NAME = :p_ci_pipelines
  COLUMN = :pipeline_id
  TARGET_COLUMN = :id
  PARTITION_COLUMN = :partition_id
  FK_NAME = :fk_rails_e214655a86_p

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
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_COLUMN, TARGET_COLUMN],
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      name: FK_NAME,
      validate: true
    )
  end
end
