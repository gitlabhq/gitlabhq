# frozen_string_literal: true

class QueueBackfillDescriptionVersionsForEpics < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillDescriptionVersionsForEpics"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 250

  def up
    # no-op, since the original migration was timing out.
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228582
  end

  def down
    # no-op, since the original migration was timing out.
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228582
  end
end
