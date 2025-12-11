# frozen_string_literal: true

class DropUniqueIndexSlackApiScopesOnName < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    remove_concurrent_index_by_name :slack_api_scopes, 'index_slack_api_scopes_on_name'
  end

  def down
    add_concurrent_index :slack_api_scopes,
      :name,
      unique: true,
      name: 'index_slack_api_scopes_on_name'
  end
end
