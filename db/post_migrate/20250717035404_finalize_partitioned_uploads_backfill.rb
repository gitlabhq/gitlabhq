# frozen_string_literal: true

class FinalizePartitionedUploadsBackfill < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op:
    #   This migration is a no-op because the original migration was re-enqueued with a new version.
    #   The new migration is 20251201121648_queue_re_enqueue_backfill_partitioned_uploads.rb
  end

  def down; end
end
