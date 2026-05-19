# frozen_string_literal: true

class AddNotNullConstraintToOauthApplicationsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  def up
    add_not_null_constraint :oauth_applications, :organization_id
  end

  def down
    remove_not_null_constraint :oauth_applications, :organization_id
  end
end
