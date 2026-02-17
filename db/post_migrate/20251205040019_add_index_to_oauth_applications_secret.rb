# frozen_string_literal: true

class AddIndexToOauthApplicationsSecret < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  INDEX_NAME = 'index_oauth_applications_on_secret'

  def up
    add_concurrent_index :oauth_applications, :secret, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :oauth_applications, INDEX_NAME
  end
end
