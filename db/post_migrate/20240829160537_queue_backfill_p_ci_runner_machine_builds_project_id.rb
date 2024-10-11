# frozen_string_literal: true

class QueueBackfillPCiRunnerMachineBuildsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  MIGRATION = "BackfillPCiRunnerMachineBuildsProjectId"

  def up
    # no-op because the original migration started failing with Sidekiq::Shutdown,
    # which was fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168420
  end

  def down
    # no-op because the original migration started failing with Sidekiq::Shutdown,
    # which was fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168420
  end
end
