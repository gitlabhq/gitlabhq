# frozen_string_literal: true

class AddIssueUserMentionsNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :issue_user_mentions, :namespace_id
  end

  def down
    remove_not_null_constraint :issue_user_mentions, :namespace_id
  end
end
