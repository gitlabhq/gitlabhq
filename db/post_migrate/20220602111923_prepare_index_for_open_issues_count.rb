# frozen_string_literal: true

class PrepareIndexForOpenIssuesCount < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'idx_open_issues_on_project_id_and_confidential'

  def up
    prepare_async_index :issues, [:project_id, :confidential], where: 'state_id = 1', name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :issues, INDEX_NAME
  end
end
