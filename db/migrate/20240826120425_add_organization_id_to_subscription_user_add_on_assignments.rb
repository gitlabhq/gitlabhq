# frozen_string_literal: true

class AddOrganizationIdToSubscriptionUserAddOnAssignments < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :subscription_user_add_on_assignments, :organization_id, :bigint
  end
end
