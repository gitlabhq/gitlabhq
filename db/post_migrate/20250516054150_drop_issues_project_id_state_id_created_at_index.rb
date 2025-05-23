# frozen_string_literal: true

class DropIssuesProjectIdStateIdCreatedAtIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_project_id_and_state_id_and_created_at_and_id'
  COLUMNS = %i[project_id state_id created_at id]

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, COLUMNS, name: INDEX_NAME
  end
end
