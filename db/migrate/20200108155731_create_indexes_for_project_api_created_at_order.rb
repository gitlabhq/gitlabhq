# frozen_string_literal: true

class CreateIndexesForProjectApiCreatedAtOrder < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, %i(visibility_level created_at id), order: { id: :desc }, name: 'index_projects_on_visibility_level_created_at_id_desc'
    add_concurrent_index :projects, %i(visibility_level created_at id), order: { created_at: :desc, id: :desc }, name: 'index_projects_on_visibility_level_created_at_desc_id_desc'
    remove_concurrent_index_by_name :projects, 'index_projects_on_visibility_level_and_created_at_and_id'
  end

  def down
    add_concurrent_index :projects, %i(visibility_level created_at id), name: 'index_projects_on_visibility_level_and_created_at_and_id'
    remove_concurrent_index_by_name :projects, 'index_projects_on_visibility_level_created_at_id_desc'
    remove_concurrent_index_by_name :projects, 'index_projects_on_visibility_level_created_at_desc_id_desc'
  end
end
