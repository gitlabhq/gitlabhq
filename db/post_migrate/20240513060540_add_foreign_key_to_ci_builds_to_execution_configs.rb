# frozen_string_literal: true

class AddForeignKeyToCiBuildsToExecutionConfigs < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '17.1'

  SOURCE_TABLE_NAME = :p_ci_builds
  TARGET_TABLE_NAME = :p_ci_builds_execution_configs
  COLUMN = [:partition_id, :execution_config_id]
  TARGET_COLUMN = [:partition_id, :id]
  FK_NAME = :fk_rails_25dc49c011

  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      column: COLUMN,
      target_column: TARGET_COLUMN,
      on_update: :cascade,
      on_delete: :nullify,
      validate: false,
      reverse_lock_order: true,
      name: FK_NAME
    )

    prepare_partitioned_async_foreign_key_validation(
      SOURCE_TABLE_NAME, COLUMN,
      name: FK_NAME
    )
  end

  def down
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- We need this.
    # More details - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150451#note_1885229123
    with_lock_retries do
      Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME) do |partition|
        remove_foreign_key_if_exists(
          partition.identifier, TARGET_TABLE_NAME,
          name: FK_NAME,
          reverse_lock_order: true
        )
      end
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end
end
