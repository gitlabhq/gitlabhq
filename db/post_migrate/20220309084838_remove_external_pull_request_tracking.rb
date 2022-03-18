# frozen_string_literal: true

class RemoveExternalPullRequestTracking < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    untrack_record_deletions(:external_pull_requests)
  end

  def down
    track_record_deletions(:external_pull_requests)
  end
end
