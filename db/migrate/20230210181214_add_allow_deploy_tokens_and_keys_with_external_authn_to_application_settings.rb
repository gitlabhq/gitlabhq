# frozen_string_literal: true

class AddAllowDeployTokensAndKeysWithExternalAuthnToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column(:application_settings, :allow_deploy_tokens_and_keys_with_external_authn, :boolean,
      default: false, null: false)
  end
end
