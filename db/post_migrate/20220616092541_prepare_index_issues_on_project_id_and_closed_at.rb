# frozen_string_literal: true

class PrepareIndexIssuesOnProjectIdAndClosedAt < Gitlab::Database::Migration[2.0]
  NEW_INDEX_NAME_1 = 'index_issues_on_project_id_closed_at_desc_state_id_and_id'
  NEW_INDEX_NAME_2 = 'index_issues_on_project_id_closed_at_state_id_and_id'

  def up
    # Index to improve performance when sorting issues by closed_at desc
    prepare_async_index :issues, 'project_id, closed_at DESC NULLS LAST, state_id, id', name: NEW_INDEX_NAME_1

    # Index to improve performance when sorting issues by closed_at asc
    # This replaces the old index which didn't account for state_id and id
    prepare_async_index :issues, [:project_id, :closed_at, :state_id, :id], name: NEW_INDEX_NAME_2
  end

  def down
    unprepare_async_index_by_name :issues, NEW_INDEX_NAME_1
    unprepare_async_index_by_name :issues, NEW_INDEX_NAME_2
  end
end
