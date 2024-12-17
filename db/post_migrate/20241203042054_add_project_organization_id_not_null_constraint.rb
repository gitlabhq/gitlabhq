# frozen_string_literal: true

class AddProjectOrganizationIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :projects, :organization_id, validate: false
  end

  def down
    remove_not_null_constraint :projects, :organization_id
  end
end
