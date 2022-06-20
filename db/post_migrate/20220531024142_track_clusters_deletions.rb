# frozen_string_literal: true

class TrackClustersDeletions < Gitlab::Database::Migration[2.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    track_record_deletions(:clusters)
  end

  def down
    untrack_record_deletions(:clusters)
  end
end
