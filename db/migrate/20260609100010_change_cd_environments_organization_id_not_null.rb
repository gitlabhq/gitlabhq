# frozen_string_literal: true

class ChangeCdEnvironmentsOrganizationIdNotNull < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    remove_multi_column_not_null_constraint(:cd_environments, :group_id, :organization_id)
    add_not_null_constraint :cd_environments, :organization_id
  end

  def down
    remove_not_null_constraint :cd_environments, :organization_id
    add_multi_column_not_null_constraint(:cd_environments, :group_id, :organization_id)
  end
end
