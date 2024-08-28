# frozen_string_literal: true

class AddSubscriptionUserAddOnAssignmentsOrganizationIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    install_sharding_key_assignment_trigger(
      table: :subscription_user_add_on_assignments,
      sharding_key: :organization_id,
      parent_table: :subscription_add_on_purchases,
      parent_sharding_key: :organization_id,
      foreign_key: :add_on_purchase_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :subscription_user_add_on_assignments,
      sharding_key: :organization_id,
      parent_table: :subscription_add_on_purchases,
      parent_sharding_key: :organization_id,
      foreign_key: :add_on_purchase_id
    )
  end
end
