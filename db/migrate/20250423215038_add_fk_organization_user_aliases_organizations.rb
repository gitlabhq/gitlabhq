# frozen_string_literal: true

class AddFkOrganizationUserAliasesOrganizations < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  def up
    add_concurrent_foreign_key :organization_user_aliases, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :organization_user_aliases, column: :organization_id
    end
  end
end
