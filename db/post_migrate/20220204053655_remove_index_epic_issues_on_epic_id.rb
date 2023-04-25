# frozen_string_literal: true

class RemoveIndexEpicIssuesOnEpicId < Gitlab::Database::Migration[1.0]
  INDEX = 'index_epic_issues_on_epic_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :epic_issues, name: INDEX
  end

  def down
    add_concurrent_index :epic_issues, :epic_id, name: INDEX
  end
end
