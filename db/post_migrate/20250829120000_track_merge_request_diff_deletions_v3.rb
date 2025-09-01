# frozen_string_literal: true

class TrackMergeRequestDiffDeletionsV3 < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.4'

  def up
    drop_trigger(:merge_request_diffs, :merge_request_diffs_loose_fk_trigger, if_exists: true)
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
