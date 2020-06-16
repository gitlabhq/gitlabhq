# frozen_string_literal: true

class AddProjectsForeignKeyToProjectAccessTokens < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_access_tokens, :projects, column: :project_id
  end

  def down
    remove_foreign_key_if_exists :project_access_tokens, column: :project_id
  end
end
