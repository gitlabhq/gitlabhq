# frozen_string_literal: true

class AddBigintFkIssuesDuplicatedToId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = :issues
  TARGET_TABLE_NAME = :issues
  BIGINT_COLUMN = :duplicated_to_id_convert_to_bigint
  FK_NAME = :fk_9c4516d665

  def up
    return if skip_migration?

    # rubocop:disable Migration/ForeignKeysToDestroyServiceTables -- duplicates the existing
    # fk_9c4516d665 on the bigint shadow column, so it introduces no new dependent records
    add_concurrent_foreign_key(
      TABLE_NAME,
      TARGET_TABLE_NAME,
      column: BIGINT_COLUMN,
      target_column: :id,
      name: tmp_foreign_key_name(FK_NAME),
      on_delete: :nullify,
      reverse_lock_order: true
    )
    # rubocop:enable Migration/ForeignKeysToDestroyServiceTables
  end

  def down
    return if skip_migration?

    with_lock_retries do
      remove_foreign_key_if_exists(
        TABLE_NAME,
        TARGET_TABLE_NAME,
        name: tmp_foreign_key_name(FK_NAME),
        reverse_lock_order: true
      )
    end
  end

  private

  def skip_migration?
    unless column_exists?(TABLE_NAME, BIGINT_COLUMN)
      say "No conversion column found - migration skipped"
      return true
    end

    false
  end
end
