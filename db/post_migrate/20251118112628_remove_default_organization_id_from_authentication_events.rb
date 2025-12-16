# frozen_string_literal: true

class RemoveDefaultOrganizationIdFromAuthenticationEvents < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    remove_column_default(:authentication_events, :organization_id)
  end

  def down
    change_column_default(:authentication_events, :organization_id, from: nil, to: 1)
  end
end
