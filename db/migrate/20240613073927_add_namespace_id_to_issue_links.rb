# frozen_string_literal: true

class AddNamespaceIdToIssueLinks < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :issue_links, :namespace_id, :bigint
  end
end
