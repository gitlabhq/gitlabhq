# frozen_string_literal: true

class AddTemporaryIndexForNotesWithMentions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_CONDITION = "note LIKE '%@%'::text"
  INDEX_NAME = 'note_mentions_temp_index'

  EPIC_MENTIONS_INDEX_NAME = 'epic_mentions_temp_index'
  DESIGN_MENTIONS_INDEX_NAME = 'design_mentions_temp_index'

  def up
    # create temporary index for notes with mentions, may take well over 1h
    add_concurrent_index(:notes, [:id, :noteable_type], where: INDEX_CONDITION, name: INDEX_NAME)

    # cleanup previous temporary indexes, as we'll be usig the single one
    remove_concurrent_index(:notes, :id, name: EPIC_MENTIONS_INDEX_NAME)
    remove_concurrent_index(:notes, :id, name: DESIGN_MENTIONS_INDEX_NAME)
  end

  def down
    remove_concurrent_index(:notes, :id, name: INDEX_NAME)

    add_concurrent_index(:notes, :id, where: "#{INDEX_CONDITION} AND noteable_type='Epic'", name: EPIC_MENTIONS_INDEX_NAME)
    add_concurrent_index(:notes, :id, where: "#{INDEX_CONDITION} AND noteable_type='DesignManagement::Design'", name: DESIGN_MENTIONS_INDEX_NAME)
  end
end
