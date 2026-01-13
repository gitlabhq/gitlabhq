# frozen_string_literal: true

class AddNotValidForeignKeyConstraintToPoolRepositoriesOnOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_foreign_key(
      :pool_repositories, :organizations,
      column: :organization_id,
      on_delete: :cascade, validate: false
    )
  end

  def down
    remove_foreign_key_if_exists :pool_repositories, column: :organization_id
  end
end
