# frozen_string_literal: true

class AddOrganizationIdToAuthenticationEvents < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_column :authentication_events, :organization_id, :bigint, null: false, default: 1
  end

  def down
    remove_column :authentication_events, :organization_id
  end
end
