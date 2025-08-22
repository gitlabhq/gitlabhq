# frozen_string_literal: true

class TrackMergeRequestDiffDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.4'

  def up
    track_record_deletions(:merge_request_diffs)
  end

  def down
    untrack_record_deletions(:merge_request_diffs)
  end
end
