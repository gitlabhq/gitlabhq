# frozen_string_literal: true

class AddResourceDeployTokenEventsToWebHooks < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :web_hooks, :resource_deploy_token_events, :boolean, default: false, null: false
  end
end
