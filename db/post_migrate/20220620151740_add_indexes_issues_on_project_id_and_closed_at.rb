# frozen_string_literal: true

class AddIndexesIssuesOnProjectIdAndClosedAt < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_issues_on_project_id_and_closed_at'
  NEW_INDEX_NAME_1 = 'index_issues_on_project_id_closed_at_desc_state_id_and_id'
  NEW_INDEX_NAME_2 = 'index_issues_on_project_id_closed_at_state_id_and_id'

  def up
    # Index to improve performance when sorting issues by closed_at desc
    unless index_exists_by_name?(:issues, NEW_INDEX_NAME_1)
      add_concurrent_index :issues, 'project_id, closed_at DESC NULLS LAST, state_id, id', name: NEW_INDEX_NAME_1
    end

    # Index to improve performance when sorting issues by closed_at asc
    # This replaces the old index which didn't account for state_id and id
    unless index_exists_by_name?(:issues, NEW_INDEX_NAME_2)
      add_concurrent_index :issues, [:project_id, :closed_at, :state_id, :id], name: NEW_INDEX_NAME_2
    end

    remove_concurrent_index_by_name :issues, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :issues, [:project_id, :closed_at], name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :issues, NEW_INDEX_NAME_1
    remove_concurrent_index_by_name :issues, NEW_INDEX_NAME_2
  end
end
