# frozen_string_literal: true

class AddNamespaceIdToSentryIssues < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :sentry_issues, :namespace_id, :bigint
  end
end
