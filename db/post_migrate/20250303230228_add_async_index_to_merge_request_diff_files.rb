# frozen_string_literal: true

class AddAsyncIndexToMergeRequestDiffFiles < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  SOURCE_TABLE = :merge_request_diff_files
  INDEX_NAME = 'index_merge_request_diff_files_on_project_id'

  def up
    # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/523103
    #
    prepare_async_index SOURCE_TABLE, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index SOURCE_TABLE, INDEX_NAME
  end
end
