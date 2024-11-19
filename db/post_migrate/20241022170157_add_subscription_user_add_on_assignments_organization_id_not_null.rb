# frozen_string_literal: true

class AddSubscriptionUserAddOnAssignmentsOrganizationIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :subscription_user_add_on_assignments, :organization_id
  end

  def down
    remove_not_null_constraint :subscription_user_add_on_assignments, :organization_id
  end
end
