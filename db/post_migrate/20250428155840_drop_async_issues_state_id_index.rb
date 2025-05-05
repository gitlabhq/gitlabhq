# frozen_string_literal: true

class DropAsyncIssuesStateIdIndex < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  INDEX_NAME = 'idx_issues_on_state_id'
  COLUMNS = %i[state_id]

  def up
    prepare_async_index_removal :issues, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, COLUMNS, name: INDEX_NAME
  end
end
