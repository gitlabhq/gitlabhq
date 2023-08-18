# frozen_string_literal: true

class AddNamespaceIdToIssueSearchData < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :issue_search_data, :namespace_id, :bigint
  end

  def down
    remove_column :issue_search_data, :namespace_id
  end
end
