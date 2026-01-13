# frozen_string_literal: true

class AddNotNullConstraintMemberRolesNamespaceOrganization < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:member_roles, :namespace_id, :organization_id)
  end

  def down
    remove_multi_column_not_null_constraint(:member_roles, :namespace_id, :organization_id)
  end
end
