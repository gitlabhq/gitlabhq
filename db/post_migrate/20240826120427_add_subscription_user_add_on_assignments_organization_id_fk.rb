# frozen_string_literal: true

class AddSubscriptionUserAddOnAssignmentsOrganizationIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :subscription_user_add_on_assignments, :organizations, column: :organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :subscription_user_add_on_assignments, column: :organization_id
    end
  end
end
