# frozen_string_literal: true

class DropIssuesStateIdIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  INDEX_NAME = 'idx_issues_on_state_id'
  COLUMNS = %i[state_id]

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, COLUMNS, name: INDEX_NAME
  end
end
