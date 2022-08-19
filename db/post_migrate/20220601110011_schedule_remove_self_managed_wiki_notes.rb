# frozen_string_literal: true

class ScheduleRemoveSelfManagedWikiNotes < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'RemoveSelfManagedWikiNotes'
  INTERVAL = 2.minutes

  disable_ddl_transaction!

  def up
    return if skip_migration?

    queue_batched_background_migration(
      MIGRATION,
      :notes,
      :id,
      job_interval: INTERVAL,
      batch_size: 10_000,
      sub_batch_size: 1_000
    )
  end

  def down
    return if skip_migration?

    delete_batched_background_migration(MIGRATION, :notes, :id, [])
  end

  private

  def skip_migration?
    Gitlab.staging? || Gitlab.com?
  end
end
