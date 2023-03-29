# frozen_string_literal: true

class DeleteUnusedIndexOnMergeRequestsOnStateIdAndMergeStatus < Gitlab::Database::Migration[2.1]
  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/402491

  def up
    prepare_async_index_removal :merge_requests, [:state_id, :merge_status],
      where: "((state_id = 1) AND ((merge_status)::text = 'can_be_merged'::text))",
      name: 'idx_merge_requests_on_state_id_and_merge_status'
  end

  def down
    unprepare_async_index :merge_requests, [:state_id, :merge_status],
      where: "((state_id = 1) AND ((merge_status)::text = 'can_be_merged'::text))",
      name: 'idx_merge_requests_on_state_id_and_merge_status'
  end
end
