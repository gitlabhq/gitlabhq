# frozen_string_literal: true

class CreateProjectRepositoryStorageMoves < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :project_repository_storage_moves do |t|
      t.timestamps_with_timezone
      t.integer :project_id, limit: 8, null: false
      t.integer :state, limit: 2, default: 1, null: false
      t.text :source_storage_name, null: false
      t.text :destination_storage_name, null: false
    end

    add_index :project_repository_storage_moves, :project_id

    add_text_limit(:project_repository_storage_moves, :source_storage_name, 255, constraint_name: 'project_repository_storage_moves_source_storage_name')
    add_text_limit(:project_repository_storage_moves, :destination_storage_name, 255, constraint_name: 'project_repository_storage_moves_destination_storage_name')
  end

  def down
    remove_check_constraint(:project_repository_storage_moves, 'project_repository_storage_moves_source_storage_name')
    remove_check_constraint(:project_repository_storage_moves, 'project_repository_storage_moves_destination_storage_name')

    drop_table :project_repository_storage_moves
  end
end
