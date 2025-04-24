# frozen_string_literal: true

class AddIssueAssignmentEventsNamespaceIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :issue_assignment_events, :namespace_id
  end

  def down
    remove_not_null_constraint :issue_assignment_events, :namespace_id
  end
end
