# frozen_string_literal: true

class SwapColumnsForDeploymentMergeRequestsBigintConversion < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = 'deployment_merge_requests'
  COLUMNS = %w[deployment_id merge_request_id environment_id].freeze
  PRIMARY_KEY_NAME = 'deployment_merge_requests_pkey'

  # The bigint primary key index was prepared under the hash of this name,
  # not of PRIMARY_KEY_NAME.
  PRIMARY_KEY_SOURCE_NAME = 'deployment_merge_requests_on_deployment_id_merge_request_id_pkey'

  INDEXES = %w[
    idx_environment_merge_requests_unique_index
    index_deployment_merge_requests_on_merge_request_id
  ].freeze

  FOREIGN_KEYS = %w[
    fk_rails_dcbce9f4df
    fk_rails_86a6d8bf12
    fk_a064ff4453
  ].freeze

  def up
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)
    return unless columns_match_type?('bigint')

    ensure_no_wraparound_vacuum!
    swap
  end

  def down
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)
    return unless columns_match_type?('integer')

    ensure_no_wraparound_vacuum!

    # The swap consumed the prepared index when it became the primary key, so
    # recreate it to reverse the primary key and again to leave it behind.
    restore_primary_key_index
    swap
    restore_primary_key_index
  end

  private

  # Checked before any DDL so that `down` does not build the restored primary
  # key index ahead of the guard.
  def ensure_no_wraparound_vacuum!
    return if can_execute_on?(TABLE_NAME)

    raise StandardError,
      "Wraparound prevention vacuum detected on #{TABLE_NAME}. Please try again later or skip it."
  end

  def swap
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- bigint migration
    with_lock_retries(raise_on_exhaustion: true) do
      COLUMNS.each do |column|
        bigint_column = convert_to_bigint_column(column)

        swap_columns(TABLE_NAME, column, bigint_column)
        swap_columns_default(TABLE_NAME, column, bigint_column)
      end

      reset_all_trigger_functions(TABLE_NAME)

      swap_bigint_primary_key

      INDEXES.each { |index| swap_index_if_exists(index) }

      FOREIGN_KEYS.each do |foreign_key|
        swap_foreign_keys(TABLE_NAME, foreign_key, tmp_foreign_key_name(foreign_key))
      end
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  # Named to avoid shadowing MigrationHelpers#swap_primary_key, which wraps its
  # own with_lock_retries.
  def swap_bigint_primary_key
    drop_constraint(TABLE_NAME, PRIMARY_KEY_NAME, cascade: true)
    rename_index(TABLE_NAME, bigint_index_name(PRIMARY_KEY_SOURCE_NAME), PRIMARY_KEY_NAME)
    add_primary_key_using_index(TABLE_NAME, PRIMARY_KEY_NAME, PRIMARY_KEY_NAME)
  end

  def restore_primary_key_index
    # rubocop:disable Migration/PreventIndexCreation -- bigint migration, already created on GitLab.com
    add_concurrent_index(
      TABLE_NAME,
      %i[deployment_id_convert_to_bigint merge_request_id_convert_to_bigint],
      name: bigint_index_name(PRIMARY_KEY_SOURCE_NAME),
      unique: true
    )
    # rubocop:enable Migration/PreventIndexCreation
  end

  # swap_indexes raises when either index is missing, which would abort the
  # whole swap. Earlier conversions hit this in production.
  def swap_index_if_exists(index)
    bigint_idx_name = bigint_index_name(index)

    unless index_exists_by_name?(TABLE_NAME, index) && index_exists_by_name?(TABLE_NAME, bigint_idx_name)
      say "Skipping swap for missing index: #{index} or #{bigint_idx_name}"
      return
    end

    swap_indexes(TABLE_NAME, index, bigint_idx_name)
  end

  def columns_match_type?(column_type)
    matched = COLUMNS.all? do |column|
      column_for(TABLE_NAME, convert_to_bigint_column(column)).sql_type == column_type
    end

    say "Columns do not match type #{column_type} - migration skipped" unless matched

    matched
  end
end
