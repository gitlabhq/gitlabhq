# frozen_string_literal: true

class SwapColumnsForCiSourcesPipelinesBigintConversion < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = 'ci_sources_pipelines'
  PRIMARY_KEY_NAME = 'ci_sources_pipelines_pkey'
  COLUMNS = %w[id project_id source_project_id].freeze
  SHARDING_KEY = 'project_id'

  INDEXES = %w[
    index_ci_sources_pipelines_on_project_id
    index_ci_sources_pipelines_on_source_project_id
  ].freeze

  def up
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)

    swap
  end

  def down
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)

    swap

    # The swap renames the bigint index into the primary key, so rebuild it to
    # get back the two indexes the table had before the swap.
    restore_primary_key_index
  end

  private

  def swap
    # Create the bigint primary key index in case it was dropped before
    restore_primary_key_index

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- bigint migration
    with_lock_retries(raise_on_exhaustion: true) do
      # Swap columns
      COLUMNS.each do |column|
        swap_columns(TABLE_NAME, column, convert_to_bigint_column(column))
        swap_columns_default(TABLE_NAME, column, convert_to_bigint_column(column))
      end

      reset_all_trigger_functions(TABLE_NAME)

      # Swap PK constraint
      drop_constraint(TABLE_NAME, PRIMARY_KEY_NAME, cascade: true)
      rename_index TABLE_NAME, bigint_index_name(PRIMARY_KEY_NAME), PRIMARY_KEY_NAME
      add_primary_key_using_index(TABLE_NAME, PRIMARY_KEY_NAME, PRIMARY_KEY_NAME)

      # Swap indexes
      INDEXES.each { |index| swap_index_if_exists(index) }

      swap_not_null_check_names
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  # swap_indexes renames unconditionally and raises when either index is
  # missing, which would abort the whole swap. Earlier conversions hit this in
  # production, see 20260731080558_swap_columns_for_deployments_bigint_conversion_phase_two.rb.
  def swap_index_if_exists(index)
    bigint_idx_name = bigint_index_name(index)

    unless index_exists_by_name?(TABLE_NAME, index) && index_exists_by_name?(TABLE_NAME, bigint_idx_name)
      say "Skipping swap for missing index: #{index} or #{bigint_idx_name}"
      return
    end

    swap_indexes(TABLE_NAME, index, bigint_idx_name)
  end

  # A check constraint stays on the physical column, so after the rename the
  # sharding key check would guard the retired column. Exchanging the two names
  # puts the canonical name back on project_id, and is its own inverse.
  def swap_not_null_check_names
    unless check_constraint_exists?(TABLE_NAME, not_null_constraint_name) &&
        check_constraint_exists?(TABLE_NAME, tmp_not_null_constraint_name)
      say "Skipping constraint swap, #{not_null_constraint_name} or #{tmp_not_null_constraint_name} is missing"
      return
    end

    rename_constraint(TABLE_NAME, not_null_constraint_name, :temp_name_for_renaming)
    rename_constraint(TABLE_NAME, tmp_not_null_constraint_name, not_null_constraint_name)
    rename_constraint(TABLE_NAME, :temp_name_for_renaming, tmp_not_null_constraint_name)
  end

  def not_null_constraint_name
    check_constraint_name(TABLE_NAME, SHARDING_KEY, 'not_null')
  end

  def tmp_not_null_constraint_name
    "#{not_null_constraint_name}_tmp"
  end

  # Recreates the same bigint PK index as the preceding index-duplication migration,
  # so the swap always finds it even if it was dropped in between.
  def restore_primary_key_index
    add_bigint_column_indexes(TABLE_NAME, :id)
  end
end
