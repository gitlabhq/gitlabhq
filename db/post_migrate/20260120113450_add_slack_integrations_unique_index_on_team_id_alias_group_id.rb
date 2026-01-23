# frozen_string_literal: true

class AddSlackIntegrationsUniqueIndexOnTeamIdAliasGroupId < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_slack_integrations_on_team_id_alias_group_id'

  def up
    add_concurrent_index :slack_integrations, %i[team_id alias group_id], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :slack_integrations, INDEX_NAME
  end
end
