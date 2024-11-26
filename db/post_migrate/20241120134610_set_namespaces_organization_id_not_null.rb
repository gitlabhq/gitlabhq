# frozen_string_literal: true

class SetNamespacesOrganizationIdNotNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.7'

  TABLE_NAME = :namespaces
  COLUMN_NAME = :organization_id
  CONSTRAINT_NAME = :check_2eae3bdf93

  def up
    add_not_null_constraint TABLE_NAME, COLUMN_NAME, validate: false, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_not_null_constraint TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME
  end
end
