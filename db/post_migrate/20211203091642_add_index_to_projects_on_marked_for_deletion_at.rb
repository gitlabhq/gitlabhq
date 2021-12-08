# frozen_string_literal: true

class AddIndexToProjectsOnMarkedForDeletionAt < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_not_aimed_for_deletion'

  def up
    add_concurrent_index :projects, :id, where: 'marked_for_deletion_at IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index :projects, :id, name: INDEX_NAME
  end
end
