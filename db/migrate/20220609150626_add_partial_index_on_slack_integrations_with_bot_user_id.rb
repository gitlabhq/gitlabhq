# frozen_string_literal: true

class AddPartialIndexOnSlackIntegrationsWithBotUserId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'partial_index_slack_integrations_with_bot_user_id'

  def up
    add_concurrent_index :slack_integrations, :id, name: INDEX_NAME, where: 'bot_user_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :slack_integrations, :id, name: INDEX_NAME
  end
end
