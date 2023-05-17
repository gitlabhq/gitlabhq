# frozen_string_literal: true

class AddConcurrentFkToIssueAssignmentEvents < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :issue_assignment_events,
      :issues,
      column: :issue_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :resource_assignment_events, column: :issue_id
  end
end
