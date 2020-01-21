# frozen_string_literal: true

class AddIndexToSentryIssuesSentryIssueIdentifier < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :sentry_issues, :sentry_issue_identifier
  end

  def down
    remove_concurrent_index :sentry_issues, :sentry_issue_identifier
  end
end
