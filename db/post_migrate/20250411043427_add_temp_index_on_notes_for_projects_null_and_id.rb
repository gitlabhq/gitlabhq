# frozen_string_literal: true

# This index is being added so that we can backfill the namespace where project
# id is NULL
class AddTempIndexOnNotesForProjectsNullAndId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'
  NEW_INDEX_NAME = 'tmp_index_null_project_id_on_notes'

  # Remove index issue: gitlab.com/gitlab-org/gitlab/-/issues/535969
  # Make the index async issue: gitlab.com/gitlab-org/gitlab/-/issues/535970
  def up
    # rubocop:disable Migration/PreventIndexCreation -- Will be removed once the backfilling for note is complete
    prepare_async_index(:notes,
      :id,
      name: NEW_INDEX_NAME,
      where: 'project_id is NULL')
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :notes, NEW_INDEX_NAME
  end
end
