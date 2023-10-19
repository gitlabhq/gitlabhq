# frozen_string_literal: true

class AddIndexOnProjectsForAdjournedDeletion < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_id_for_aimed_for_deletion'

  def up
    add_concurrent_index :projects,
      [:id, :marked_for_deletion_at],
      where: 'marked_for_deletion_at IS NOT NULL AND pending_delete = false',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end
end
