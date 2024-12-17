# frozen_string_literal: true

class AddNamespaceIdToIssueMetrics < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :issue_metrics, :namespace_id, :bigint
  end
end
