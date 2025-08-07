# frozen_string_literal: true

class RemoveIndexIssuesOnProjectIdAndExternalKey < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  INDEX_NAME = 'index_issues_on_project_id_and_external_key'

  # Follow-up issue to remove index https://gitlab.com/gitlab-org/gitlab/-/issues/558770
  def up
    prepare_async_index_removal :issues, [:project_id, :external_key], name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, [:project_id, :external_key], name: INDEX_NAME
  end
end
