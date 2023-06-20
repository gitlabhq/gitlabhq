# frozen_string_literal: true

class PrepareIssuesWorkItemTypeIdProjectIdIndex < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_issues_on_work_item_type_id_project_id_created_at_state'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121297
  def up
    prepare_async_index :issues, [:work_item_type_id, :project_id, :created_at, :state_id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, [:work_item_type_id, :project_id, :created_at, :state_id], name: INDEX_NAME
  end
end
