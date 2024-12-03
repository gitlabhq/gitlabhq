# frozen_string_literal: true

class IndexIssueAssignmentEventsOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_issue_assignment_events_on_namespace_id'

  def up
    add_concurrent_index :issue_assignment_events, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issue_assignment_events, INDEX_NAME
  end
end
