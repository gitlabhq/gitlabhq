class ValidateForeignKeysOnOauthOpenidRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    if Gitlab::Database.postgresql?
      execute %q{
        ALTER TABLE "oauth_openid_requests"
          VALIDATE CONSTRAINT "fk_oauth_openid_requests_oauth_access_grants_access_grant_id";
      }
    end
  end

  def down
    # noop
  end
end
