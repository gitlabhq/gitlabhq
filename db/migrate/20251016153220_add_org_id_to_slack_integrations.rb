# frozen_string_literal: true

class AddOrgIdToSlackIntegrations < Gitlab::Database::Migration[2.3]
  TABLE_NAME = :slack_integrations
  INDEX_NAME = 'index_slack_integrations_on_organization_id'
  COLUMN_NAME = :organization_id

  disable_ddl_transaction!
  milestone '18.6'

  def up
    with_lock_retries do
      add_column TABLE_NAME, COLUMN_NAME, :bigint, if_not_exists: true
    end

    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME

    with_lock_retries do
      remove_column TABLE_NAME, COLUMN_NAME, if_exists: true
    end
  end
end
