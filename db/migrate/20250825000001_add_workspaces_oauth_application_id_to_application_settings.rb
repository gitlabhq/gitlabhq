# frozen_string_literal: true

class AddWorkspacesOauthApplicationIdToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone "18.3"

  # @return [void]
  def change
    add_column :application_settings, :workspaces_oauth_application_id, :bigint, if_not_exists: true
  end
end
