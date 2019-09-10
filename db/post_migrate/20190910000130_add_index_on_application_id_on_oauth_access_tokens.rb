# frozen_string_literal: true

class AddIndexOnApplicationIdOnOauthAccessTokens < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :oauth_access_tokens, :application_id
  end

  def down
    remove_concurrent_index :oauth_access_tokens, :application_id
  end
end
