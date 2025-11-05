# frozen_string_literal: true

class AddIndexToOrganizationIdOauthApplications < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_index :oauth_applications, :organization_id, name: 'idx_oauth_applications_organization_id'
  end

  def down
    remove_concurrent_index :oauth_applications, :organization_id, name: 'idx_oauth_applications_organization_id'
  end
end
