# frozen_string_literal: true

class QueueBackfillOnboardingStatusRole < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillOnboardingStatusRole"

  def up
    # no-op because we are missing some records due to a bypass in application logic
  end

  def down
    # no-op
  end
end
