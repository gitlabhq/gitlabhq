# frozen_string_literal: true

class AddDesignManagementVersionsNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  def up
    add_not_null_constraint :design_management_versions, :namespace_id
  end

  def down
    remove_not_null_constraint :design_management_versions, :namespace_id
  end
end
