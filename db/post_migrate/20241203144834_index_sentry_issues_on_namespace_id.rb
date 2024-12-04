# frozen_string_literal: true

class IndexSentryIssuesOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_sentry_issues_on_namespace_id'

  def up
    add_concurrent_index :sentry_issues, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sentry_issues, INDEX_NAME
  end
end
