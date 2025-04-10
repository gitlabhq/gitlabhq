# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleRmIndexMergeRequestDiffsOnProjectId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_merge_request_diffs_on_project_id'

  milestone '17.11'

  def up
    prepare_async_index_removal :merge_request_diffs, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_request_diffs, :project_id, name: INDEX_NAME
  end
end
