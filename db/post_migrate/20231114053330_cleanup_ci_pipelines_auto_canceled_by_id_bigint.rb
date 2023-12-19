# frozen_string_literal: true

class CleanupCiPipelinesAutoCanceledByIdBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone "16.7"

  TABLE = :ci_pipelines
  REFERENCING_TABLE = :ci_pipelines
  COLUMN = :auto_canceled_by_id
  OLD_COLUMN = :auto_canceled_by_id_convert_to_bigint
  INDEX_NAME = :index_ci_pipelines_on_auto_canceled_by_id_bigint
  OLD_FK_NAME = :fk_67e4288f3a

  def up
    with_lock_retries(raise_on_exhaustion: true) do
      cleanup_conversion_of_integer_to_bigint(TABLE, [COLUMN])
    end
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, [COLUMN])

    add_concurrent_index(TABLE, OLD_COLUMN, name: INDEX_NAME)

    add_concurrent_foreign_key(
      TABLE, TABLE,
      column: OLD_COLUMN, name: OLD_FK_NAME,
      on_delete: :nullify, validate: true, reverse_lock_order: true
    )
  end
end
