# frozen_string_literal: true

class AddFkOrganizationUserDetailsOrganizations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_foreign_key :organization_user_details, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :organization_user_details, column: :organization_id
    end
  end
end
