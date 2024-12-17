# frozen_string_literal: true

class AddNamespaceIdToIssueUserMentions < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :issue_user_mentions, :namespace_id, :bigint
  end
end
