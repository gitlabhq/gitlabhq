# frozen_string_literal: true

class QueueBackfillPartitionedUploads < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillPartitionedUploads"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 7000
  SUB_BATCH_SIZE = 300

  def up
    # no-op:
    #   This migration is a no-op because the original migration was re-enqueued with a new version.
    #   The new migration is 20251201121648_queue_re_enqueue_backfill_partitioned_uploads.rb
  end

  def down
    # no-op
  end
end
