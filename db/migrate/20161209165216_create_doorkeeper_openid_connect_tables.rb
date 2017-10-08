class CreateDoorkeeperOpenidConnectTables < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :oauth_openid_requests do |t|
      t.integer :access_grant_id, null: false
      t.string :nonce, null: false
    end

    if Gitlab::Database.postgresql?
      # add foreign key without validation to avoid downtime on PostgreSQL,
      # also see db/post_migrate/20170209140523_validate_foreign_keys_on_oauth_openid_requests.rb
      execute %q{
        ALTER TABLE "oauth_openid_requests"
          ADD CONSTRAINT "fk_oauth_openid_requests_oauth_access_grants_access_grant_id"
          FOREIGN KEY ("access_grant_id")
          REFERENCES "oauth_access_grants" ("id")
          NOT VALID;
      }
    else
      execute %q{
        ALTER TABLE oauth_openid_requests
          ADD CONSTRAINT fk_oauth_openid_requests_oauth_access_grants_access_grant_id
          FOREIGN KEY (access_grant_id)
          REFERENCES oauth_access_grants (id);
      }
    end
  end

  def down
    drop_table :oauth_openid_requests
  end
end
