# frozen_string_literal: true

class PrepareIndexesForMergeRequestsBigintConversionStageThree < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = 'merge_requests'
  BIGINT_COLUMNS = [:id_convert_to_bigint, :author_id_convert_to_bigint].freeze
  INDEXES = [
    {
      name: 'merge_requests_pkey',
      columns: [:id_convert_to_bigint],
      options: { unique: true }
    },
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
    return if skip_migration?

    # rubocop:disable Migration/PreventIndexCreation -- Bigint migration
    INDEXES.each do |index|
      options = index[:options] || {}
      prepare_async_index(TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options)
    end
    # rubocop:enable Migration/PreventIndexCreation
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
