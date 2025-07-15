# frozen_string_literal: true

class PrepareIndexesForMergeRequestDiffsBigintConversion < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '18.2'

  TABLE_NAME = 'merge_request_diffs'
  BIGINT_COLUMNS = [:id_convert_to_bigint, :merge_request_id_convert_to_bigint].freeze
  INDEXES = [
    {
      name: 'merge_request_diffs_pkey',
      columns: [:id_convert_to_bigint],
      options: { unique: true }
    },
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

  def up
    return if skip_migration?

    INDEXES.each do |index|
      options = index[:options] || {}
      prepare_async_index(TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options)
    end
  end

  def down
    return if skip_migration?

    INDEXES.each do |index|
      options = index[:options] || {}
      unprepare_async_index(TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options)
    end
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
    BIGINT_COLUMNS.all? { |column| column_exists?(TABLE_NAME, column) }
  end
end
