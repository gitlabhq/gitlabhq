# frozen_string_literal: true

class RemoveMrdcArchivedIndexOnProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diff_commits_archived
  INDEX_NAME = 'index_merge_request_diff_commits_on_project_id'

  def up
    return unless Gitlab.com_except_jh? && table_exists?(TABLE_NAME)

    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    return unless Gitlab.com_except_jh? && table_exists?(TABLE_NAME)

    add_concurrent_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end
end
