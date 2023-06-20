# frozen_string_literal: true

class QueueCleanupPersonalAccessTokensWithNilExpiresAt < Gitlab::Database::Migration[2.1]
  # per: https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#requeuing-batched-background-migrations
  # > When you requeue the batched background migration, turn the original queuing
  # > into a no-op by clearing up the #up and #down methods of the migration
  # > performing the requeuing. Otherwise, the batched background migration is
  # > queued multiple times on systems that are upgrading multiple patch releases
  # > at once.
  #
  # being re-run via https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123002
  def up; end

  def down; end
end
