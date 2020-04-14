# frozen_string_literal: true

class AddIndexOnCreatorIdCreatedAtIdToProjectsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:creator_id, :created_at, :id]
  end

  def down
    remove_concurrent_index :projects, [:creator_id, :created_at, :id]
  end
end
