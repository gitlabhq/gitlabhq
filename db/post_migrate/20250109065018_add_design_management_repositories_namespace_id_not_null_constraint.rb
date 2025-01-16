# frozen_string_literal: true

class AddDesignManagementRepositoriesNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :design_management_repositories, :namespace_id
  end

  def down
    remove_not_null_constraint :design_management_repositories, :namespace_id
  end
end
