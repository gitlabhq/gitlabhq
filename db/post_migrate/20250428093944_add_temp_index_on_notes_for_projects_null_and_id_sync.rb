# frozen_string_literal: true

class AddTempIndexOnNotesForProjectsNullAndIdSync < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_null_project_id_on_notes'

  # rubocop:disable Migration/PreventIndexCreation -- Already added in a async index creation
  # db/post_migrate/20250411043427_add_temp_index_on_notes_for_projects_null_and_id.rb
  def up
    add_concurrent_index :notes, :id, name: INDEX_NAME, where: 'project_id is NULL'
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end
end
