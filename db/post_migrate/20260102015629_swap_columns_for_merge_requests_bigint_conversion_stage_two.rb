# frozen_string_literal: true

class SwapColumnsForMergeRequestsBigintConversionStageTwo < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers

  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = 'merge_requests'
  COLUMNS = %w[target_project_id latest_merge_request_diff_id last_edited_by_id].freeze

  INDEXES = %w[
    index_merge_requests_on_target_project_id_and_iid
    index_merge_requests_on_target_project_id_and_merged_commit_sha
    index_merge_requests_on_target_project_id_and_source_branch
    index_merge_requests_on_target_project_id_and_squash_commit_sha
    index_merge_requests_on_target_project_id_and_target_branch
    index_merge_requests_for_latest_diffs_with_state_merged
    index_merge_requests_on_latest_merge_request_diff_id
    idx_mrs_on_target_id_and_created_at_and_state_id
    index_merge_requests_on_target_project_id_and_created_at_and_id
    index_merge_requests_on_target_project_id_and_updated_at_and_id
    index_merge_requests_on_tp_id_and_merge_commit_sha_and_id
    index_merge_requests_on_author_id_and_target_project_id
    index_on_merge_requests_for_latest_diffs
  ].freeze

  FOREIGN_KEYS = [
    {
      table_name: TABLE_NAME,
      fk_name: 'fk_a6963e8447'
    },
    {
      table_name: TABLE_NAME,
      fk_name: 'fk_06067f5644'
    }
  ]
  PARTITIONED_FOREIGN_KEYS = [
    {
      table_name: 'p_generated_ref_commits',
      fk_name: 'fk_generated_ref_commits_merge_request_id'
    }
  ].freeze

  def up
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('bigint')

    swap
  end

  def down
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('integer')

    swap
  end

  private

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
      swap_columns_default(TABLE_NAME, 'target_project_id', convert_to_bigint_column('target_project_id'))

      reset_all_trigger_functions(TABLE_NAME)

      INDEXES.each do |index|
        bigint_idx_name = bigint_index_name(index)
        swap_indexes(TABLE_NAME, index, bigint_idx_name)
      end

      FOREIGN_KEYS.each do |foreign_key|
        bigint_fk_temp_name = tmp_name(foreign_key[:fk_name])
        swap_foreign_keys(foreign_key[:table_name], foreign_key[:fk_name], bigint_fk_temp_name)
      end

      PARTITIONED_FOREIGN_KEYS.each do |foreign_key|
        bigint_fk_temp_name = tmp_name(foreign_key[:fk_name])
        swap_partitioned_foreign_keys(foreign_key[:table_name], foreign_key[:fk_name], bigint_fk_temp_name)
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
