# frozen_string_literal: true

class AddIndexOnCreatorIdAndCreatedAtToProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_projects_on_creator_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:creator_id, :created_at]

    remove_concurrent_index_by_name :projects, INDEX_NAME
  end

  def down
    add_concurrent_index :projects, :creator_id, name: INDEX_NAME

    remove_concurrent_index :projects, [:creator_id, :created_at]
  end
end
