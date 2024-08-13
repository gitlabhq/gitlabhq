# frozen_string_literal: true

class AddAsyncFkAutoCanceledByIdForCiPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_pipelines
  TARGET_TABLE_NAME = :ci_pipelines
  COLUMN = :auto_canceled_by_id
  PARTITION_COLUMN = :auto_canceled_by_partition_id
  TARGET_COLUMN = :id
  TARGET_PARTITION_COLUMN = :partition_id
  FK_NAME = :fk_262d4c2d19_p

  def up
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [TARGET_PARTITION_COLUMN, TARGET_COLUMN],
      validate: false,
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :nullify,
      name: FK_NAME
    )

    prepare_async_foreign_key_validation(SOURCE_TABLE_NAME, [PARTITION_COLUMN, COLUMN], name: FK_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(SOURCE_TABLE_NAME, [PARTITION_COLUMN, COLUMN], name: FK_NAME)

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
