# frozen_string_literal: true

class RemoveIndexIssuesOnProjectHealthStatus < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  INDEX_NAME = 'index_issues_on_project_health_status_asc_work_item_type'
  COLUMNS = [:project_id, :health_status, :id, :state_id, :work_item_type_id]

  # Follow-up issue to remove index https://gitlab.com/gitlab-org/gitlab/-/issues/559053
  def up
    prepare_async_index_removal :issues, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, COLUMNS, name: INDEX_NAME
  end
end
