# frozen_string_literal: true

class AddIssuesIncidentTypeTempIndexAsyncDotCom < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'tmp_index_issues_on_issue_type_and_id_only_incidents'
  INCIDENT_ENUM_VALUE = 1

  # TODO: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117728
  def up
    prepare_async_index :issues, [:issue_type, :id], name: INDEX_NAME, where: "issue_type = #{INCIDENT_ENUM_VALUE}"
  end

  def down
    unprepare_async_index :issues, [:issue_type, :id], name: INDEX_NAME
  end
end
