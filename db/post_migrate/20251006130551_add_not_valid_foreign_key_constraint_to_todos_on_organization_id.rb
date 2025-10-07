# frozen_string_literal: true

class AddNotValidForeignKeyConstraintToTodosOnOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_concurrent_foreign_key(
      :todos, :organizations,
      column: :organization_id,
      on_delete: :cascade, validate: false
    )
  end

  def down
    remove_foreign_key_if_exists :todos, column: :organization_id
  end
end
