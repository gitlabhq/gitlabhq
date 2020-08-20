# frozen_string_literal: true

class AddIndexToProjectsAimedForDeletion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  PROJECTS_AIMED_FOR_DELETION_INDEX_NAME = "index_projects_aimed_for_deletion"
  MARKED_FOR_DELETION_PROJECTS_INDEX_NAME = "index_projects_on_marked_for_deletion_at"

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects,
                         :marked_for_deletion_at,
                         where: "marked_for_deletion_at IS NOT NULL AND pending_delete = false",
                         name: PROJECTS_AIMED_FOR_DELETION_INDEX_NAME

    remove_concurrent_index_by_name :projects, MARKED_FOR_DELETION_PROJECTS_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, PROJECTS_AIMED_FOR_DELETION_INDEX_NAME

    add_concurrent_index :projects, :marked_for_deletion_at, where: 'marked_for_deletion_at IS NOT NULL'
  end
end
