# frozen_string_literal: true

class QueueBackfillAdminModeScopeForPersonalAccessTokens < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  # no-op as the original migration is rescheduled
  # in migrations version 20230406093640
  def up; end

  def down; end
end
