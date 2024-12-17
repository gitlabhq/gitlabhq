# frozen_string_literal: true

class AddNamespaceIdToIssueAssignmentEvents < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :issue_assignment_events, :namespace_id, :bigint
  end
end
