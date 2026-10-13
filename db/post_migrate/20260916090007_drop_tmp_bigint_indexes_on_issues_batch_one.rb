# frozen_string_literal: true

class DropTmpBigintIndexesOnIssuesBatchOne < Gitlab::Database::Migration[2.3]
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

  INDEXES = [
    {
      name: 'index_issues_on_closed_by_id',
      columns: [:closed_by_id_convert_to_bigint]
    },
    {
      name: 'index_issues_on_duplicated_to_id',
      columns: [:duplicated_to_id_convert_to_bigint],
      options: { where: 'duplicated_to_id_convert_to_bigint IS NOT NULL' }
    },
    {
      name: 'index_issues_on_last_edited_by_id',
      columns: [:last_edited_by_id_convert_to_bigint]
    },
    {
      name: 'index_issues_on_moved_to_id',
      columns: [:moved_to_id_convert_to_bigint],
      options: { where: 'moved_to_id_convert_to_bigint IS NOT NULL' }
    },
    {
      name: 'index_issues_on_promoted_to_epic_id',
      columns: [:promoted_to_epic_id_convert_to_bigint],
      options: { where: 'promoted_to_epic_id_convert_to_bigint IS NOT NULL' }
    },
    {
      name: 'index_issues_on_updated_by_id',
      columns: [:updated_by_id_convert_to_bigint],
      options: { where: 'updated_by_id_convert_to_bigint IS NOT NULL' }
    }
  ].freeze

  def up
    vacuum_detection
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('integer')

    INDEXES.each do |index|
      remove_concurrent_index_by_name(TABLE_NAME, bigint_index_name(index[:name]))
    end
  end

  def down
    vacuum_detection
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('integer')

    INDEXES.each do |index|
      options = index[:options] || {}
      add_concurrent_index TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options
    end
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

  def vacuum_detection
    return if can_execute_on?(:issues)

    raise StandardError,
      "Wraparound prevention vacuum detected on issues table" \
        "Please try again later."
  end
end
