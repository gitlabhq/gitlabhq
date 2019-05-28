# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanUpNoteableIdForNotesOnCommits < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  TEMP_INDEX_NAME = 'index_notes_on_commit_with_null_noteable_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:notes, TEMP_INDEX_NAME)

    add_concurrent_index(:notes, :id, where: "noteable_type = 'Commit' AND noteable_id IS NOT NULL", name: TEMP_INDEX_NAME)

    # rubocop:disable Migration/UpdateLargeTable
    update_column_in_batches(:notes, :noteable_id, nil, batch_size: 300) do |table, query|
      query.where(
        table[:noteable_type].eq('Commit').and(table[:noteable_id].not_eq(nil))
      )
    end

    remove_concurrent_index_by_name(:notes, TEMP_INDEX_NAME)
  end

  def down
  end
end
