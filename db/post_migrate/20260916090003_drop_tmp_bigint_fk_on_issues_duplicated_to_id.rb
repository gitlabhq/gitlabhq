# frozen_string_literal: true

class DropTmpBigintFkOnIssuesDuplicatedToId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = 'issues'
  COLUMN = 'duplicated_to_id'
  FK_NAME = :fk_9c4516d665_tmp
  TARGET_TABLE = :issues

  def up
    vacuum_detection
    return if skip_migration

    with_lock_retries(raise_on_exhaustion: true) do
      remove_foreign_key_if_exists(TABLE_NAME, TARGET_TABLE, name: FK_NAME)
    end
  end

  def down
    vacuum_detection
    return if skip_migration

    add_concurrent_foreign_key(
      TABLE_NAME,
      TARGET_TABLE,
      column: convert_to_bigint_column(COLUMN),
      target_column: :id,
      name: FK_NAME,
      on_delete: :nullify,
      validate: true
    )
  end

  private

  def skip_migration
    unless column_exists?(TABLE_NAME, convert_to_bigint_column(COLUMN))
      say "No conversion column found - migration skipped"
      return true
    end

    unless column_for(TABLE_NAME, convert_to_bigint_column(COLUMN)).sql_type == 'integer'
      say "Column is not swapped - migration skipped"
      return true
    end

    false
  end

  def vacuum_detection
    return if can_execute_on?(:issues)

    raise StandardError,
      "Wraparound prevention vacuum detected on issues table" \
        "Please try again later."
  end
end
