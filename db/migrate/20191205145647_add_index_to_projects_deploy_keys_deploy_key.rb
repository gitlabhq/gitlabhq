# frozen_string_literal: true

class AddIndexToProjectsDeployKeysDeployKey < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_index :deploy_keys_projects, :deploy_key_id
  end

  def down
    remove_concurrent_index :deploy_keys_projects, :deploy_key_id
  end
end
