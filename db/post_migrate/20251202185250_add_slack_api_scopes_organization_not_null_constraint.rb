# frozen_string_literal: true

class AddSlackApiScopesOrganizationNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :slack_api_scopes, :organization_id, validate: false
  end

  def down
    remove_not_null_constraint :slack_api_scopes, :organization_id
  end
end
