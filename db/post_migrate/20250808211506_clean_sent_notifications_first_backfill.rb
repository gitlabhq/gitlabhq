# frozen_string_literal: true

class CleanSentNotificationsFirstBackfill < Gitlab::Database::Migration[2.3]
  MIGRATION = "BackfillSentNotificationsAfterPartition"

  milestone '18.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    delete_batched_background_migration(MIGRATION, :sent_notifications, :id, [])
  end

  def down; end
end
