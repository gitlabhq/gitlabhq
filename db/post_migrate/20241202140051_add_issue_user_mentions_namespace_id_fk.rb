# frozen_string_literal: true

class AddIssueUserMentionsNamespaceIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :issue_user_mentions, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :issue_user_mentions, column: :namespace_id
    end
  end
end
