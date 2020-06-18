# frozen_string_literal: true

class AddPersonalAccessTokenForeignKeyToProjectAccessTokens < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_access_tokens, :personal_access_tokens, column: :personal_access_token_id
  end

  def down
    remove_foreign_key_if_exists :project_access_tokens, column: :personal_access_token_id
  end
end
