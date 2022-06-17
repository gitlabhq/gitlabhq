# frozen_string_literal: true

class AddIndexForOpenIssuesCount < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_open_issues_on_project_id_and_confidential'

  def up
    add_concurrent_index :issues, [:project_id, :confidential], where: 'state_id = 1', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
