# frozen_string_literal: true

class AddDesignManagementDesignsVersionsNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :design_management_designs_versions, :namespace_id
  end

  def down
    remove_not_null_constraint :design_management_designs_versions, :namespace_id
  end
end
