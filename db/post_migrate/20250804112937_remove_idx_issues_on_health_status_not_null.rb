# frozen_string_literal: true

class RemoveIdxIssuesOnHealthStatusNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  INDEX_NAME = 'idx_issues_on_health_status_not_null'

  # Follow-up issue to remove index https://gitlab.com/gitlab-org/gitlab/-/issues/372205
  def up
    prepare_async_index_removal :issues, [:health_status], name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, [:health_status], where: "health_status IS NOT NULL", name: INDEX_NAME
  end
end
