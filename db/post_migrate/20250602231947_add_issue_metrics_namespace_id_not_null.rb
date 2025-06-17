# frozen_string_literal: true

class AddIssueMetricsNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :issue_metrics, :namespace_id
  end

  def down
    remove_not_null_constraint :issue_metrics, :namespace_id
  end
end
