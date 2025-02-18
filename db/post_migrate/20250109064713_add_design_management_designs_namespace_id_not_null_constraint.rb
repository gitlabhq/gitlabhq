# frozen_string_literal: true

class AddDesignManagementDesignsNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :design_management_designs, :namespace_id
  end

  def down
    remove_not_null_constraint :design_management_designs, :namespace_id
  end
end
