# frozen_string_literal: true

class DropAsyncIssuesConfidentialIndex < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  INDEX_NAME = 'index_issues_on_confidential'
  COLUMNS = %i[confidential]

  def up
    prepare_async_index_removal :issues, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, COLUMNS, name: INDEX_NAME
  end
end
