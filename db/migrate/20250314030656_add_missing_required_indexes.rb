# frozen_string_literal: true

class AddMissingRequiredIndexes < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  def up
    # These were never added when we added the foreign keys. There was an assumption that they would be covered by
    # composite indexes, but the composite index in question did not start with this column so it would not have worked.
    add_concurrent_index :subscription_add_on_purchases, :subscription_add_on_id,
      name: :idx_subscription_add_on_purchases_on_subscription_add_on_id
    add_concurrent_index :slack_integrations_scopes, :slack_api_scope_id,
      name: :idx_slack_integrations_scopes_on_slack_api_scope_id
  end

  def down
    remove_concurrent_index_by_name :subscription_add_on_purchases,
      :idx_subscription_add_on_purchases_on_subscription_add_on_id
    remove_concurrent_index_by_name :slack_integrations_scopes, :idx_slack_integrations_scopes_on_slack_api_scope_id
    remove_concurrent_index_by_name :users, :idx_users_on_application_setting_terms
  end
end
