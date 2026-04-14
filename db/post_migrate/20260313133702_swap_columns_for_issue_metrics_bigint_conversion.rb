# frozen_string_literal: true

class SwapColumnsForIssueMetricsBigintConversion < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '18.10'

  TABLE_NAME = 'issue_metrics'
  PRIMARY_KEY_NAME = 'issue_metrics_pkey'
  COLUMNS = %w[id issue_id].freeze

  INDEXES = %w[
    index_issue_metrics_on_issue_id_and_timestamps
    index_unique_issue_metrics_issue_id
  ].freeze

  FOREIGN_KEY = "fk_rails_4bb543d85d"

  def up
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)

    swap
  end

  def down
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)

    swap

    restore_primary_key_index
  end

  private

  def swap
    # Create bigint indexes in case they were dropped before
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
      INDEXES.each do |index|
        bigint_idx_name = bigint_index_name(index)

        swap_indexes(TABLE_NAME, index, bigint_idx_name)
      end

      # Swap foreign key
      bigint_fk_temp_name = tmp_foreign_key_name(FOREIGN_KEY)
      swap_foreign_keys(TABLE_NAME, FOREIGN_KEY, bigint_fk_temp_name)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def restore_primary_key_index
    index_name = bigint_index_name(PRIMARY_KEY_NAME)

    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, name: index_name, unique: true
  end
end
