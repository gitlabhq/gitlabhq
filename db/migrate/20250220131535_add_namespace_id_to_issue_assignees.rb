# frozen_string_literal: true

class AddNamespaceIdToIssueAssignees < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :issue_assignees, :namespace_id, :bigint
  end
end
