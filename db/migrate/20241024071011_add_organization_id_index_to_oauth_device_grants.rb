# frozen_string_literal: true

class AddOrganizationIdIndexToOauthDeviceGrants < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def up
    add_concurrent_index :oauth_device_grants, :organization_id, name: "idx_oauth_device_grants_on_organization_id"
    add_concurrent_foreign_key :oauth_device_grants, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    remove_concurrent_index :oauth_device_grants, :organization_id, name: "idx_oauth_device_grants_on_organization_id"
    remove_foreign_key :oauth_device_grants, :organizations, column: :organization_id, on_delete: :cascade
  end
end
