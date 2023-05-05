# frozen_string_literal: true

class TrackExternalPullRequestsDeletes < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    track_record_deletions(:external_pull_requests)
  end

  def down
    untrack_record_deletions(:external_pull_requests)
  end
end
