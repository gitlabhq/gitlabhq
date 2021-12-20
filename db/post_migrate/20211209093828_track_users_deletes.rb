# frozen_string_literal: true

class TrackUsersDeletes < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    track_record_deletions(:users)
  end

  def down
    untrack_record_deletions(:users)
  end
end
