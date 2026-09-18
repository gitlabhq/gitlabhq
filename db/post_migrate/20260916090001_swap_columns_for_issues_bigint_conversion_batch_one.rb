# frozen_string_literal: true

# This migration does not need to no-op when failed.
# Type validation prevents accidental schema modifications.
class SwapColumnsForIssuesBigintConversionBatchOne < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = 'issues'
  COLUMNS = %w[
    closed_by_id
    duplicated_to_id
    last_edited_by_id
    moved_to_id
    promoted_to_epic_id
    updated_by_id
  ].freeze

  INDEXES = %w[
    index_issues_on_closed_by_id
    index_issues_on_duplicated_to_id
    index_issues_on_last_edited_by_id
    index_issues_on_moved_to_id
    index_issues_on_promoted_to_epic_id
    index_issues_on_updated_by_id
  ].freeze

  FOREIGN_KEYS = %w[
    fk_c63cbf6c25
    fk_9c4516d665
    fk_a194299be1
    fk_df75a7c8b8
    fk_ffed080f01
  ].freeze

  # We intentionally do not call `ensure_backfill_conversion_of_integer_to_bigint_is_finished`.
  # The backfill for the issues bigint columns was performed by the custom
  # `BackfillIssuesCorrectWorkItemTypeId` batched background migration (finalized by
  # 20241030165330), not by `CopyColumnUsingBackgroundMigrationJob` which that helper checks for.
  # Calling it would raise because no matching migration record exists for this table.
  def up
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('bigint')

    swap
  end

  def down
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('integer')

    swap
  end

  def swap
    unless can_execute_on?(:issues)
      raise StandardError,
        "Wraparound prevention vacuum detected on issues table" \
          "Please try again later."
    end

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      COLUMNS.each do |column|
        swap_columns(TABLE_NAME, column, convert_to_bigint_column(column))
      end

      reset_all_trigger_functions(TABLE_NAME)

      INDEXES.each do |index|
        bigint_idx_name = bigint_index_name(index)
        swap_indexes(TABLE_NAME, index, bigint_idx_name)
      end

      FOREIGN_KEYS.each do |foreign_key|
        bigint_fk_temp_name = tmp_name(foreign_key)
        swap_foreign_keys(TABLE_NAME, foreign_key, bigint_fk_temp_name)
      end
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def tmp_name(name)
    "#{name}_tmp"
  end

  def skip_migration_as_bigint_columns_non_exist
    unless COLUMNS.all? { |column| column_exists?(TABLE_NAME, convert_to_bigint_column(column)) }
      say "No conversion columns found - migration skipped"
      return true
    end

    false
  end

  def skip_migration_as_bigint_columns_type_non_match(column_type)
    unless COLUMNS.all? { |column| column_for(TABLE_NAME, convert_to_bigint_column(column)).sql_type == column_type }
      say "Columns are converted - migration skipped"
      return true
    end

    false
  end
end
