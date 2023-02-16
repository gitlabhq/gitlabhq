# frozen_string_literal: true

class AddIndexOnMergeRequestDiffsExternalDiff < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_merge_request_diffs_on_external_diff'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/390399
  def up
    prepare_async_index :merge_request_diffs, :external_diff, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_request_diffs, :external_diff, name: INDEX_NAME
  end
end
