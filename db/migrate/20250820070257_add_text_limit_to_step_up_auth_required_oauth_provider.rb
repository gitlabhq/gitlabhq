# frozen_string_literal: true

class AddTextLimitToStepUpAuthRequiredOauthProvider < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    add_text_limit :namespace_settings, :step_up_auth_required_oauth_provider, 255
  end

  def down
    remove_text_limit :namespace_settings, :step_up_auth_required_oauth_provider
  end
end
