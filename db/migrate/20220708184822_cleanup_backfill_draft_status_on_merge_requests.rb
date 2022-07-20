# frozen_string_literal: true

class CleanupBackfillDraftStatusOnMergeRequests < Gitlab::Database::Migration[2.0]
  def up
    # no-op
    #
    # moved to post-deployment migration:
    # db/post_migrate/20220713133515_cleanup_backfill_draft_statuses_on_merge_requests.rb
  end

  def down
    # no-op
  end
end
