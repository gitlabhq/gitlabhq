# frozen_string_literal: true

class AddMemberRoleIdToSamlProviders < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def change
    add_column :saml_providers, :member_role_id, :bigint
  end
end
