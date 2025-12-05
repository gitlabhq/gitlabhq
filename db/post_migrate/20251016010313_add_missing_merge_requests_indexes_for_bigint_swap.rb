# frozen_string_literal: true

class AddMissingMergeRequestsIndexesForBigintSwap < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  TABLE_NAME = 'merge_requests'
  INDEXES = [
    {
      name: 'index_merge_requests_on_assignee_id',
      columns: [:assignee_id]
    },
    {
      name: 'index_merge_requests_on_merge_user_id',
      columns: [:merge_user_id],
      options: { where: "merge_user_id IS NOT NULL" }
    },
    {
      name: 'index_merge_requests_on_updated_by_id',
      columns: [:updated_by_id],
      options: { where: "updated_by_id IS NOT NULL" }
    },
    {
      name: 'index_merge_requests_on_milestone_id',
      columns: [:milestone_id]
    },
    {
      name: 'idx_merge_requests_on_source_project_and_branch_state_opened',
      columns: [:source_project_id, :source_branch],
      options: { where: "state_id = 1" }
    },
    {
      name: 'index_merge_requests_on_source_project_id_and_source_branch',
      columns: [:source_project_id, :source_branch]
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
