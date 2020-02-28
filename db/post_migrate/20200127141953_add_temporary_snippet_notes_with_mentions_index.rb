# frozen_string_literal: true

class AddTemporarySnippetNotesWithMentionsIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'snippet_mentions_temp_index'
  INDEX_CONDITION = "note LIKE '%@%'::text AND notes.noteable_type = 'Snippet'"

  disable_ddl_transaction!

  def up
    # create temporary index for notes with mentions, may take well over 1h
    add_concurrent_index(:notes, :id, where: INDEX_CONDITION, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:notes, :id, where: INDEX_CONDITION, name: INDEX_NAME)
  end
end
