# frozen_string_literal: true

class AddSentryIssuesNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :sentry_issues, :namespace_id
  end

  def down
    remove_not_null_constraint :sentry_issues, :namespace_id
  end
end
