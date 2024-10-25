# frozen_string_literal: true

class AddOrganizationIdToOauthDeviceGrants < Gitlab::Database::Migration[2.2]
  DEFAULT_ORGANIZATION_ID = 1

  disable_ddl_transaction!
  milestone '17.6'

  def change
    add_column :oauth_device_grants, :organization_id, :bigint,
      default: DEFAULT_ORGANIZATION_ID, null: false, if_not_exists: true
  end
end
