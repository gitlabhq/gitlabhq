# frozen_string_literal: true

class AddScimOauthAccessTokensOrganizationIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  def up
    add_not_null_constraint :scim_oauth_access_tokens, :organization_id
  end

  def down
    remove_not_null_constraint :scim_oauth_access_tokens, :organization_id
  end
end
