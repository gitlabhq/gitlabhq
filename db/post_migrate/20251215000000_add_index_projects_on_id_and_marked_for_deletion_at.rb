# frozen_string_literal: true

class AddIndexProjectsOnIdAndMarkedForDeletionAt < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  TABLE = :projects
  INDEX_NAME = 'index_projects_on_id_and_marked_for_deletion_at'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- index needed for marked_for_deletion_before scope optimization
    # We'll drop `index_projects_aimed_for_deletion` & `index_projects_id_for_aimed_for_deletion` in a future MR.
    add_concurrent_index TABLE, [:id, :marked_for_deletion_at],
      where: 'marked_for_deletion_at IS NOT NULL',
      name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name TABLE, name: INDEX_NAME
  end
end
