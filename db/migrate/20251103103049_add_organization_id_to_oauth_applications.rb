# frozen_string_literal: true

class AddOrganizationIdToOauthApplications < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def change
    add_column :oauth_applications, :organization_id, :bigint
  end
end
