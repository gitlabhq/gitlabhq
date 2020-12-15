# frozen_string_literal: true

class AddIndexProjectsOnImportTypeAndCreatorId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:creator_id, :import_type, :created_at],
                         where: 'import_type IS NOT NULL',
                         name: 'index_projects_on_creator_id_import_type_and_created_at_partial'
  end

  def down
    remove_concurrent_index_by_name :projects, 'index_projects_on_creator_id_import_type_and_created_at_partial'
  end
end
