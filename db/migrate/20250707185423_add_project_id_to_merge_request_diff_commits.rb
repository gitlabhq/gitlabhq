# frozen_string_literal: true

class AddProjectIdToMergeRequestDiffCommits < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :merge_request_diff_commits, :project_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- Needed for future partitioning and sharding
  end
end
