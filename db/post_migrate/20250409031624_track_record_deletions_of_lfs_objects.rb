# frozen_string_literal: true

class TrackRecordDeletionsOfLfsObjects < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '17.11'

  def up
    track_record_deletions(:lfs_objects)
  end

  def down
    untrack_record_deletions(:lfs_objects)
  end
end
