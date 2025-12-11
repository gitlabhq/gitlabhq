# frozen_string_literal: true

class SyncBigintIndexesCreationOnMergeRequestsStageTwo < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '18.7'

  TABLE_NAME = 'merge_requests'
  BIGINT_COLUMNS = [
    :target_project_id_convert_to_bigint,
    :latest_merge_request_diff_id_convert_to_bigint,
    :last_edited_by_id_convert_to_bigint
  ].freeze
  INDEXES = [
    {
      name: 'index_merge_requests_on_target_project_id_and_iid',
      columns: [:target_project_id_convert_to_bigint, :iid],
      options: { unique: true }
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_merged_commit_sha',
      columns: [:target_project_id_convert_to_bigint, :merged_commit_sha]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_source_branch',
      columns: [:target_project_id_convert_to_bigint, :source_branch]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_squash_commit_sha',
      columns: [:target_project_id_convert_to_bigint, :squash_commit_sha]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_target_branch',
      columns: [:target_project_id_convert_to_bigint, :target_branch],
      options: { where: "state_id = 1 AND merge_when_pipeline_succeeds = true" }
    },
    {
      name: 'index_merge_requests_for_latest_diffs_with_state_merged',
      columns: [:latest_merge_request_diff_id_convert_to_bigint, :target_project_id_convert_to_bigint],
      options: { where: "state_id = 3" }
    },
    {
      name: 'index_merge_requests_on_latest_merge_request_diff_id',
      columns: [:latest_merge_request_diff_id_convert_to_bigint]
    },
    {
      name: 'idx_mrs_on_target_id_and_created_at_and_state_id',
      columns: [:target_project_id_convert_to_bigint, :state_id, :created_at, :id]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_created_at_and_id',
      columns: [:target_project_id_convert_to_bigint, :created_at, :id]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_updated_at_and_id',
      columns: [:target_project_id_convert_to_bigint, :updated_at, :id]
    },
    {
      name: 'index_merge_requests_on_tp_id_and_merge_commit_sha_and_id',
      columns: [:target_project_id_convert_to_bigint, :merge_commit_sha, :id]
    },
    {
      name: 'index_merge_requests_on_author_id_and_target_project_id',
      columns: [:author_id, :target_project_id_convert_to_bigint]
    },
    {
      name: 'index_on_merge_requests_for_latest_diffs',
      columns: [:target_project_id_convert_to_bigint],
      options: { include: [:id, :latest_merge_request_diff_id_convert_to_bigint] }
    }
  ].freeze

  def up
    return if skip_migration?

    # rubocop:disable Migration/PreventIndexCreation -- bigint migration
    INDEXES.each do |index|
      options = index[:options] || {}
      add_concurrent_index TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options
    end
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    return if skip_migration?

    INDEXES.each do |index|
      remove_concurrent_index_by_name TABLE_NAME, bigint_index_name(index[:name])
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
