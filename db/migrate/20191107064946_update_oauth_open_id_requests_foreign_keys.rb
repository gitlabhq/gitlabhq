# frozen_string_literal: true

class UpdateOauthOpenIdRequestsForeignKeys < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:oauth_openid_requests, :oauth_access_grants, column: :access_grant_id, on_delete: :cascade, name: new_foreign_key_name)
    remove_foreign_key_if_exists(:oauth_openid_requests, name: existing_foreign_key_name)
  end

  def down
    add_concurrent_foreign_key(:oauth_openid_requests, :oauth_access_grants, column: :access_grant_id, on_delete: false, name: existing_foreign_key_name)
    remove_foreign_key_if_exists(:oauth_openid_requests, name: new_foreign_key_name)
  end

  private

  def new_foreign_key_name
    concurrent_foreign_key_name(:oauth_openid_requests, :access_grant_id)
  end

  def existing_foreign_key_name
    'fk_oauth_openid_requests_oauth_access_grants_access_grant_id'
  end
end
