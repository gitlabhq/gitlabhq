# frozen_string_literal: true

class ReplaceIssuesAuthorizationIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_open_issues_on_project_and_confidential_and_author_and_id'
  OLD_INDEX_NAME = 'idx_open_issues_on_project_id_and_confidential'

  def up
    add_concurrent_index :issues, [:project_id, :confidential, :author_id, :id], name: INDEX_NAME, where: 'state_id = 1'
    remove_concurrent_index_by_name :issues, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :issues, [:project_id, :confidential], name: OLD_INDEX_NAME, where: 'state_id = 1'
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
