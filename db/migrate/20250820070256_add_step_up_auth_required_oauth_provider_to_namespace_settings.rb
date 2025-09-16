# frozen_string_literal: true

class AddStepUpAuthRequiredOauthProviderToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  # rubocop:disable Migration/AddLimitToTextColumns -- Limit is added in 20250820070257_add_text_limit_to_step_up_auth_required_oauth_provider
  def up
    add_column :namespace_settings, :step_up_auth_required_oauth_provider, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :namespace_settings, :step_up_auth_required_oauth_provider
  end
end
