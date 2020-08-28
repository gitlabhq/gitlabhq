# frozen_string_literal: true

class AddProjectsIndexOnImportTypeCreatorIdCreatedAt < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_imported_projects_on_import_type_creator_id_created_at'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects,
      [:import_type, :creator_id, :created_at],
      where: 'import_type IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end
end
