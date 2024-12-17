# frozen_string_literal: true

class AddProjectIdToMergeRequestDiffs < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.7'

  def change
    add_column :merge_request_diffs, :project_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
  end
end
