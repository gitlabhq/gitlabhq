# frozen_string_literal: true

class RemoveSlackIntegrationsUniqueIndex < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_slack_integrations_on_team_id_and_alias'

  def up
    remove_concurrent_index_by_name :slack_integrations, INDEX_NAME
  end

  def down
    add_concurrent_index :slack_integrations, %i[team_id alias], unique: true, name: INDEX_NAME
  end
end
