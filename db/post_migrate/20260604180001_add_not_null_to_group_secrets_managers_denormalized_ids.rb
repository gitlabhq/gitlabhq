# frozen_string_literal: true

class AddNotNullToGroupSecretsManagersDenormalizedIds < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_not_null_constraint :group_secrets_managers, :organization_id
    add_not_null_constraint :group_secrets_managers, :root_namespace_id
  end

  def down
    remove_not_null_constraint :group_secrets_managers, :organization_id
    remove_not_null_constraint :group_secrets_managers, :root_namespace_id
  end
end
