# frozen_string_literal: true

class FinalizeHkCreateJiraCloudAppIntegrationForJiraConnectSubscription < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CreateJiraCloudAppIntegrationForJiraConnectSubscription',
      table_name: :jira_connect_subscriptions,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
