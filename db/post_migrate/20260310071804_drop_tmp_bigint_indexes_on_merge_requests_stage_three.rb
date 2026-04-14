# frozen_string_literal: true

class DropTmpBigintIndexesOnMergeRequestsStageThree < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '18.11'

  TABLE_NAME = 'merge_requests'
  COLUMNS = %w[id author_id].freeze

  INDEXES = [
    {
      name: 'idx_merge_requests_on_id_and_merge_jid',
      columns: [:id_convert_to_bigint, :merge_jid],
      options: { where: 'merge_jid IS NOT NULL AND state_id = 4' }
    },
    {
      name: 'idx_merge_requests_on_merged_state',
      columns: [:id_convert_to_bigint],
      options: { where: 'state_id = 3' }
    },
    {
      name: 'idx_merge_requests_on_unmerged_state_id',
      columns: [:id_convert_to_bigint],
      options: { where: 'state_id <> 3' }
    },
    {
      name: 'index_merge_requests_on_author_id_and_id',
      columns: [:author_id_convert_to_bigint, :id_convert_to_bigint]
    },
    {
      name: 'index_merge_requests_on_author_id_and_created_at',
      columns: [:author_id_convert_to_bigint, :created_at]
    },
    {
      name: 'idx_mrs_on_target_id_and_created_at_and_state_id',
      columns: [:target_project_id, :state_id, :created_at, :id_convert_to_bigint]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_created_at_and_id',
      columns: [:target_project_id, :created_at, :id_convert_to_bigint]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_updated_at_and_id',
      columns: [:target_project_id, :updated_at, :id_convert_to_bigint]
    },
    {
      name: 'index_merge_requests_on_tp_id_and_merge_commit_sha_and_id',
      columns: [:target_project_id, :merge_commit_sha, :id_convert_to_bigint]
    },
    {
      name: 'index_on_merge_requests_for_latest_diffs',
      columns: [:target_project_id],
      options: { include: [:id_convert_to_bigint, :latest_merge_request_diff_id] }
    },
    {
      name: 'index_merge_requests_on_author_id_and_target_project_id',
      columns: [:author_id_convert_to_bigint, :target_project_id]
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

  private

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

  def vacuum_detection
    return if can_execute_on?(:merge_requests)

    raise StandardError,
      "Wraparound prevention vacuum detected on merge_requests table" \
        "Please try again later."
  end
end
