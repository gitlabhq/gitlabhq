# frozen_string_literal: true

class QueueBackfillSentNotificationsAfterPartition < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def up
    # no-op
    # Backfill will need to be re-scheduled in the future
  end

  def down; end
end
