# frozen_string_literal: true

class AddOrganizationIdToMemberRoles < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :member_roles, :organization_id, :bigint
  end
end
