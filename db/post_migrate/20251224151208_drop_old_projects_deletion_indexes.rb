# frozen_string_literal: true

class DropOldProjectsDeletionIndexes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  TABLE = :projects
  INDEX_AIMED_FOR_DELETION = 'index_projects_aimed_for_deletion'
  INDEX_ID_FOR_AIMED_FOR_DELETION = 'index_projects_id_for_aimed_for_deletion'

  def up
    remove_concurrent_index_by_name TABLE, name: INDEX_AIMED_FOR_DELETION
    remove_concurrent_index_by_name TABLE, name: INDEX_ID_FOR_AIMED_FOR_DELETION
  end

  def down
    add_concurrent_index TABLE, :marked_for_deletion_at,
      where: '(marked_for_deletion_at IS NOT NULL) AND (pending_delete = false)',
      name: INDEX_AIMED_FOR_DELETION

    add_concurrent_index TABLE, [:id, :marked_for_deletion_at],
      where: '(marked_for_deletion_at IS NOT NULL) AND (pending_delete = false)',
      name: INDEX_ID_FOR_AIMED_FOR_DELETION
  end
end
