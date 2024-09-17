# frozen_string_literal: true

class AddDisablePasswordAuthenticationForEnterpriseUsersToSamlProviders < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  enable_lock_retries!

  def change
    add_column :saml_providers, :disable_password_authentication_for_enterprise_users, :boolean, default: false
  end
end
