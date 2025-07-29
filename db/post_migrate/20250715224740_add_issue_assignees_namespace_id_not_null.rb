# frozen_string_literal: true

class AddIssueAssigneesNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :issue_assignees, :namespace_id
  end

  def down
    remove_not_null_constraint :issue_assignees, :namespace_id
  end
end
