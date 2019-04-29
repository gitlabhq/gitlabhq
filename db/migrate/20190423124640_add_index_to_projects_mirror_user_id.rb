# frozen_string_literal: true

class AddIndexToProjectsMirrorUserId < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, :mirror_user_id
  end

  def down
    remove_concurrent_index :projects, :mirror_user_id
  end
end
