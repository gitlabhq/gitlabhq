# frozen_string_literal: true

class CleanupBackfillMissingNamespaceIdOnNotes < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  MIGRATION = 'BackfillMissingNamespaceIdOnNotes'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # rubocop:disable Migration/BatchMigrationsPostOnly -- Delete in a migration rather than post_migration
    # to delete the batched migration before it might be enqueued
    delete_batched_background_migration(MIGRATION, :notes, :id, [])
    # rubocop:enable Migration/BatchMigrationsPostOnly
  end

  def down; end
end
