# frozen_string_literal: true

class AddStaleToAnalyzerNamespaceStatuses < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :analyzer_namespace_statuses, :stale, :bigint, null: false, default: 0
  end
end
