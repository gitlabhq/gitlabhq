# frozen_string_literal: true

class AddOrganizationIdIndexToAuthenticationEvents < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_concurrent_index :authentication_events, :organization_id
    add_concurrent_foreign_key :authentication_events, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    remove_concurrent_index :authentication_events, :organization_id,
      name: 'index_authentication_events_on_organization_id'
    remove_foreign_key :authentication_events, :organizations, column: :organization_id, on_delete: :cascade
  end
end
