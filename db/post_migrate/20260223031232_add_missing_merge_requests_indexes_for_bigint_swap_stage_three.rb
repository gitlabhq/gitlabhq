# frozen_string_literal: true

class AddMissingMergeRequestsIndexesForBigintSwapStageThree < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  TABLE_NAME = 'merge_requests'
  INDEXES = [
    {
      name: 'idx_merge_requests_on_id_and_merge_jid',
      columns: [:id, :merge_jid],
      options: { where: 'merge_jid IS NOT NULL AND state_id = 4' }
    },
    {
      name: 'idx_merge_requests_on_merged_state',
      columns: [:id],
      options: { where: 'state_id = 3' }
    },
    {
      name: 'idx_merge_requests_on_unmerged_state_id',
      columns: [:id],
      options: { where: 'state_id <> 3' }
    },
    {
      name: 'index_merge_requests_on_author_id_and_id',
      columns: [:author_id, :id]
    },
    {
      name: 'index_merge_requests_on_author_id_and_created_at',
      columns: [:author_id, :created_at]
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
      name: 'index_on_merge_requests_for_latest_diffs',
      columns: [:target_project_id],
      options: { include: [:id, :latest_merge_request_diff_id] }
    },
    {
      name: 'index_merge_requests_on_author_id_and_target_project_id',
      columns: [:author_id, :target_project_id]
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
