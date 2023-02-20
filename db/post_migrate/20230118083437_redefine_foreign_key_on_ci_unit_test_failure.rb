# frozen_string_literal: true

class RedefineForeignKeyOnCiUnitTestFailure < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_unit_test_failures
  TARGET_TABLE_NAME = :ci_builds
  COLUMN = :build_id
  TARGET_COLUMN = :id
  OLD_FK_NAME = :fk_0f09856e1f_p
  PARTITION_COLUMN = :partition_id

  def up
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_COLUMN, TARGET_COLUMN],
      validate: true,
      reverse_lock_order: true,
      name: new_foreign_key_name,
      on_update: :cascade
    )

    with_lock_retries do
      remove_foreign_key_if_exists(SOURCE_TABLE_NAME, name: OLD_FK_NAME)
    end
  end

  def down
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_COLUMN, TARGET_COLUMN],
      validate: true,
      reverse_lock_order: true,
      name: OLD_FK_NAME
    )

    with_lock_retries do
      remove_foreign_key_if_exists(SOURCE_TABLE_NAME, name: new_foreign_key_name)
    end
  end

  private

  def new_foreign_key_name
    "#{concurrent_foreign_key_name(SOURCE_TABLE_NAME, [PARTITION_COLUMN, COLUMN])}_p"
  end
end
