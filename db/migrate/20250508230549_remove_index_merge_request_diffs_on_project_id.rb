# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveIndexMergeRequestDiffsOnProjectId < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_merge_request_diffs_on_project_id'

  disable_ddl_transaction!
  milestone '18.1'

  def up
    remove_concurrent_index_by_name :merge_request_diffs, name: INDEX_NAME
  end

  def down
    add_concurrent_index :merge_request_diffs, :project_id, name: INDEX_NAME
  end
end
