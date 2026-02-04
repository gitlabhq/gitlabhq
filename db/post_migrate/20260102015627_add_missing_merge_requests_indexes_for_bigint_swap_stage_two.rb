# frozen_string_literal: true

class AddMissingMergeRequestsIndexesForBigintSwapStageTwo < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  TABLE_NAME = 'merge_requests'
  INDEXES = [
    {
      name: 'index_merge_requests_on_target_project_id_and_iid',
      columns: [:target_project_id, :iid],
      options: { unique: true }
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_merged_commit_sha',
      columns: [:target_project_id, :merged_commit_sha]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_source_branch',
      columns: [:target_project_id, :source_branch]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_squash_commit_sha',
      columns: [:target_project_id, :squash_commit_sha]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_target_branch',
      columns: [:target_project_id, :target_branch],
      options: { where: "state_id = 1 AND merge_when_pipeline_succeeds = true" }
    },
    {
      name: 'index_merge_requests_for_latest_diffs_with_state_merged',
      columns: [:latest_merge_request_diff_id, :target_project_id],
      options: { where: "state_id = 3" }
    },
    {
      name: 'index_merge_requests_on_latest_merge_request_diff_id',
      columns: [:latest_merge_request_diff_id]
    },
    {
      name: 'idx_mrs_on_target_id_and_created_at_and_state_id',
      columns: [:target_project_id, :state_id, :created_at, :id]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_created_at_and_id',
      columns: [:target_project_id, :created_at, :id]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_updated_at_and_id',
      columns: [:target_project_id, :updated_at, :id]
    },
    {
      name: 'index_merge_requests_on_tp_id_and_merge_commit_sha_and_id',
      columns: [:target_project_id, :merge_commit_sha, :id]
    },
    {
      name: 'index_merge_requests_on_author_id_and_target_project_id',
      columns: [:author_id, :target_project_id]
    },
    {
      name: 'index_on_merge_requests_for_latest_diffs',
      columns: [:target_project_id],
      options: { include: [:id, :latest_merge_request_diff_id] }
    }
  ].freeze

  def up
    # rubocop:disable Migration/PreventIndexCreation -- add existing indexes for bigint migration
    INDEXES.each do |index|
      options = index[:options] || {}
      add_concurrent_index TABLE_NAME, index[:columns], name: index[:name], if_not_exists: true, **options
    end
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    # no-op
  end
end
