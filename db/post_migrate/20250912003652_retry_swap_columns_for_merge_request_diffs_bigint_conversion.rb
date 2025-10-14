# frozen_string_literal: true

class RetrySwapColumnsForMergeRequestDiffsBigintConversion < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '18.4'

  TABLE_NAME = 'merge_request_diffs'
  COLUMNS = [:id, :merge_request_id].freeze

  PRIMARY_KEY = {
    name: 'merge_request_diffs_pkey',
    columns: [:id_convert_to_bigint],
    options: { unique: true }
  }

  INDEXES = [
    {
      name: 'index_merge_request_diffs_by_id_partial',
      columns: [:id_convert_to_bigint],
      options: { where: 'files_count > 0 AND (NOT stored_externally OR stored_externally IS NULL)' }
    },
    {
      name: 'index_merge_request_diffs_on_merge_request_id_and_id',
      columns: [:merge_request_id_convert_to_bigint, :id_convert_to_bigint]
    },
    {
      name: 'index_merge_request_diffs_on_project_id_and_id',
      columns: [:project_id, :id_convert_to_bigint]
    },
    {
      name: 'index_merge_request_diffs_on_unique_merge_request_id',
      columns: [:merge_request_id_convert_to_bigint],
      options: { where: 'diff_type = 2', unique: true }
    }
  ].freeze

  FOREIGN_KEYS = [
    {
      source_table: :merge_request_diffs,
      column: :merge_request_id_convert_to_bigint,
      target_table: :merge_requests,
      target_column: :id,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: :fk_8483f3258f
    },
    {
      source_table: :merge_requests,
      column: :latest_merge_request_diff_id,
      target_table: :merge_request_diffs,
      target_column: :id_convert_to_bigint,
      on_delete: :nullify,
      reverse_lock_order: false,
      name: :fk_06067f5644
    },
    {
      source_table: :merge_request_diff_commits,
      column: :merge_request_diff_id,
      target_table: :merge_request_diffs,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: :fk_rails_316aaceda3
    },
    {
      source_table: :merge_request_diff_files,
      column: :merge_request_diff_id,
      target_table: :merge_request_diffs,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: :fk_rails_501aa0a391
    },
    {
      source_table: :merge_request_diff_details,
      column: :merge_request_diff_id,
      target_table: :merge_request_diffs,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: :fk_rails_86f4d24ecd
    }
  ].freeze

  def up
    return if skip_migration?

    if conversion_already_done?
      say "Conversion already done - migration skipped"
      return
    end

    swap
  end

  def down
    return if skip_migration?

    unless conversion_already_done?
      say "Conversion is not done yet - migration skipped"
      return
    end

    swap

    restore_primary_index_and_foreign_keys
  end

  private

  def skip_migration?
    unless conversion_columns_exist?
      say "No conversion columns found - migration skipped"
      return true
    end

    false
  end

  def conversion_columns_exist?
    COLUMNS.all? { |column| column_exists?(TABLE_NAME, convert_to_bigint_column(column)) }
  end

  def conversion_already_done?
    COLUMNS.all? { |column| columns_swapped?(TABLE_NAME, column) }
  end

  def can_execute_on_all_tables?
    tables = FOREIGN_KEYS.flat_map { |fk| [fk[:source_table], fk[:target_table]] }.uniq
    can_execute_on?(tables)
  end

  def swap
    unless can_execute_on_all_tables?
      raise StandardError,
        "Wraparound prevention vacuum detected on one of the tables: " \
          "[merge_request_diffs, merge_requests, merge_request_diff_commits," \
          "merge_request_diff_files, merge_request_diff_details], aborting migration." \
          "Please try again later."
    end

    # Create bigint indexes and foreign keys in case they were dropped before
    restore_primary_index_and_foreign_keys

    # Remove existing FKs from the referencing tables, so we don't have to lock on them when we drop the existing PK
    replace_foreign_keys

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      # Swap columns
      COLUMNS.each do |column|
        swap_columns(TABLE_NAME, column, convert_to_bigint_column(column))
      end

      # Reset all trigger functions
      reset_all_trigger_functions(TABLE_NAME)

      # Swap defaults
      swap_columns_default(TABLE_NAME, :id_convert_to_bigint, :id)
      swap_columns_default(TABLE_NAME, :merge_request_id_convert_to_bigint, :merge_request_id)

      # Swap PK constraint
      drop_constraint(TABLE_NAME, PRIMARY_KEY[:name], cascade: true)
      rename_index TABLE_NAME, bigint_index_name(PRIMARY_KEY[:name]), PRIMARY_KEY[:name]
      add_primary_key_using_index(TABLE_NAME, PRIMARY_KEY[:name], PRIMARY_KEY[:name])

      # Swap indexes
      INDEXES.each do |idx_metadata|
        bigint_idx_name = bigint_index_name(idx_metadata[:name])
        swap_indexes(TABLE_NAME, bigint_idx_name, idx_metadata[:name])
      end
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def replace_foreign_keys
    FOREIGN_KEYS.each do |fk_metadata|
      # Convert bigint column names back to original column names
      original_column = convert_bigint_column_to_original(fk_metadata[:column])
      original_target_column = convert_bigint_column_to_original(fk_metadata[:target_column])
      temporary_name = "#{fk_metadata[:name]}_tmp"

      # Skip if already replaced - check if final FK with bigint columns exists
      next if foreign_key_replaced?(fk_metadata)

      with_lock_retries do
        # Explicitly lock table in order of parent, child to attempt to avoid deadlocks
        tables = [fk_metadata[:source_table], fk_metadata[:target_table]]
        tables = tables.reverse if fk_metadata[:reverse_lock_order]
        execute "LOCK TABLE #{tables[0]}, #{tables[1]} IN ACCESS EXCLUSIVE MODE"

        if foreign_key_exists?(
          fk_metadata[:source_table],
          fk_metadata[:target_table],
          column: original_column,
          primary_key: original_target_column,
          name: fk_metadata[:name]
        )
          remove_foreign_key(
            fk_metadata[:source_table],
            fk_metadata[:target_table],
            column: original_column,
            primary_key: original_target_column,
            name: fk_metadata[:name]
          )
          rename_constraint(fk_metadata[:source_table], temporary_name, fk_metadata[:name])
        else
          # The temporary FKs have been created awhile ago and one of the original FK has been dropped recently.
          # So if this is the case, we need to remove the temporary FK before we can proceed with PK swap.
          remove_foreign_key_if_exists(
            fk_metadata[:source_table],
            fk_metadata[:target_table],
            column: fk_metadata[:column],
            primary_key: fk_metadata[:target_column],
            name: temporary_name
          )
        end
      end
    end
  end

  def convert_bigint_column_to_original(column)
    column.to_s.sub('_convert_to_bigint', '').to_sym
  end

  def restore_primary_index_and_foreign_keys
    # rubocop:disable Migration/PreventIndexCreation -- bigint migration

    # Recreate bigint primary key index if doesn't exist
    add_concurrent_index(
      TABLE_NAME,
      PRIMARY_KEY[:columns],
      name: bigint_index_name(PRIMARY_KEY[:name]),
      **PRIMARY_KEY[:options]
    )
    # rubocop:enable Migration/PreventIndexCreation

    # Recreate bigint foreign keys
    FOREIGN_KEYS.each do |fk_metadata|
      # Skip creating temp FK if the final FK already exists (already replaced)
      next if foreign_key_replaced?(fk_metadata)

      add_concurrent_foreign_key(
        fk_metadata[:source_table],
        fk_metadata[:target_table],
        column: fk_metadata[:column],
        target_column: fk_metadata[:target_column],
        name: "#{fk_metadata[:name]}_tmp",
        on_delete: fk_metadata[:on_delete],
        reverse_lock_order: fk_metadata[:reverse_lock_order]
      )
    end
  end

  def foreign_key_replaced?(fk_metadata)
    foreign_key_exists?(
      fk_metadata[:source_table],
      fk_metadata[:target_table],
      column: fk_metadata[:column],
      primary_key: fk_metadata[:target_column],
      name: fk_metadata[:name]
    )
  end
end
