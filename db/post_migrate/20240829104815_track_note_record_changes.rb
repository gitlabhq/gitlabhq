# frozen_string_literal: true

class TrackNoteRecordChanges < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '17.4'

  def up
    track_record_deletions(:notes)
  end

  def down
    untrack_record_deletions(:notes)
  end
end
