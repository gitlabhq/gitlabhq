# frozen_string_literal: true

class DropIssuesAuthorIdIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_author_id_and_id_and_created_at'
  COLUMNS = %i[author_id id created_at]

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, COLUMNS, name: INDEX_NAME
  end
end
