# frozen_string_literal: true

class AddForeignKeyToKeysOrganization < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :keys, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :keys, column: :organization_id
  end
end
