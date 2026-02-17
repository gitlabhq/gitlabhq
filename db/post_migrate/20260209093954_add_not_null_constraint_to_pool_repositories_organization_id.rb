# frozen_string_literal: true

class AddNotNullConstraintToPoolRepositoriesOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  def up
    add_not_null_constraint :pool_repositories, :organization_id
  end

  def down
    remove_not_null_constraint :pool_repositories, :organization_id
  end
end
