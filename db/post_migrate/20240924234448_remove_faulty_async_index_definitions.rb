# frozen_string_literal: true

class RemoveFaultyAsyncIndexDefinitions < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    unprepare_async_index_by_name :merge_request_diff_commits_b5377a7a34,
      :index_merge_request_diff_commits_b5377a7a34_on_project_id
    unprepare_async_index_by_name :merge_request_diff_files_99208b8fac,
      :index_merge_request_diff_files_99208b8fac_on_project_id
  end

  def down
    # no-op
  end
end
