# frozen_string_literal: true

class DropIdxJiraConnectSubscriptionsOnInstallationId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = :idx_jira_connect_subscriptions_on_installation_id
  TABLE_NAME = :jira_connect_subscriptions

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :jira_connect_installation_id, name: INDEX_NAME
  end
end
