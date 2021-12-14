# frozen_string_literal: true

class TrackMergeRequestsDeletes < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    track_record_deletions(:merge_requests)
  end

  def down
    untrack_record_deletions(:merge_requests)
  end
end
