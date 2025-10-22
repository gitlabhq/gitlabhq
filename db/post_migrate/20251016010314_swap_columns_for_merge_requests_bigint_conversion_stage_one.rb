# frozen_string_literal: true

# This migration does not need to no-op when failed.
# Type validation prevents accidental schema modifications.
class SwapColumnsForMergeRequestsBigintConversionStageOne < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '18.6'

  TABLE_NAME = 'merge_requests'
  COLUMNS = %w[assignee_id merge_user_id updated_by_id milestone_id source_project_id].freeze

  INDEXES = %w[
    index_merge_requests_on_assignee_id
    index_merge_requests_on_merge_user_id
    index_merge_requests_on_updated_by_id
    index_merge_requests_on_milestone_id
    idx_merge_requests_on_source_project_and_branch_state_opened
    index_merge_requests_on_source_project_id_and_source_branch
  ].freeze

  FOREIGN_KEYS = %w[
    fk_6149611a04
    fk_641731faff
    fk_6a5165a692
    fk_ad525e1f87
    fk_source_project
  ].freeze

  def up
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('bigint')

    swap
  end

  def down
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('integer')

    swap
  end

  def swap
    unless can_execute_on?(:merge_requests)
      raise StandardError,
        "Wraparound prevention vacuum detected on merge_requests table" \
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
