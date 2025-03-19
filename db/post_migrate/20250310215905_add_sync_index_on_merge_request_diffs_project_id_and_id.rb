# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddSyncIndexOnMergeRequestDiffsProjectIdAndId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.11'

  INDEX_NAME = 'index_merge_request_diffs_on_project_id_and_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- This index will replace index_merge_request_diffs_on_project_id
    add_concurrent_index :merge_request_diffs, [:project_id, :id], name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :merge_request_diffs, INDEX_NAME
  end
end
