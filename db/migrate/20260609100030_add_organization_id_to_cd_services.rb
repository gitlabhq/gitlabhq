# frozen_string_literal: true

class AddOrganizationIdToCdServices < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_column :cd_services, :organization_id, :bigint, if_not_exists: true

    add_concurrent_index :cd_services, :organization_id
    add_not_null_constraint :cd_services, :organization_id
    change_column_null :cd_services, :group_id, true
  end

  def down
    change_column_null :cd_services, :group_id, false
    remove_not_null_constraint :cd_services, :organization_id
    remove_column :cd_services, :organization_id
  end
end
