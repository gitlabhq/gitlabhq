# frozen_string_literal: true

class AddNamespaceIdToEpicIssues < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :epic_issues, :namespace_id, :bigint
  end
end
