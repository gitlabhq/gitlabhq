# frozen_string_literal: true

class TrackMergeRequestDiffDeletionsV2 < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.4'

  def up
    with_lock_retries do
      track_record_deletions(:merge_request_diffs)
    end
  end

  def down
    with_lock_retries do
      untrack_record_deletions(:merge_request_diffs)
    end
  end
end
