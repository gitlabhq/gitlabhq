# frozen_string_literal: true

class TrackTagsDeletions < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    track_record_deletions(:tags)
  end

  def down
    untrack_record_deletions(:tags)
  end
end
