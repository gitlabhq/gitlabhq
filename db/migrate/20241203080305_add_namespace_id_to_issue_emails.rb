# frozen_string_literal: true

class AddNamespaceIdToIssueEmails < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :issue_emails, :namespace_id, :bigint
  end
end
