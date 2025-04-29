# frozen_string_literal: true

class DropAsyncIssuesAuthorIdIndex < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  INDEX_NAME = 'index_issues_on_author_id_and_id_and_created_at'
  COLUMNS = %i[author_id id created_at]

  def up
    prepare_async_index_removal :issues, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, COLUMNS, name: INDEX_NAME
  end
end
