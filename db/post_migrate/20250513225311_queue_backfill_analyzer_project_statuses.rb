# frozen_string_literal: true

class QueueBackfillAnalyzerProjectStatuses < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  MIGRATION = "BackfillAnalyzerProjectStatuses"

  def up
    # no-op because there was a bug in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193293
  end

  def down
    # no-op because there was a bug in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193293
  end
end
