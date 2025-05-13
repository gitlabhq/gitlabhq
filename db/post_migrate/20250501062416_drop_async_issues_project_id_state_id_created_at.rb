# frozen_string_literal: true

class DropAsyncIssuesProjectIdStateIdCreatedAt < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  INDEX_NAME = 'index_issues_on_project_id_and_state_id_and_created_at_and_id'
  COLUMNS = %i[project_id state_id created_at id]

  def up
    prepare_async_index_removal :issues, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, COLUMNS, name: INDEX_NAME
  end
end
