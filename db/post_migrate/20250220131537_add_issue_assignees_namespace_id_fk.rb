# frozen_string_literal: true

class AddIssueAssigneesNamespaceIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :issue_assignees, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :issue_assignees, column: :namespace_id
    end
  end
end
