# frozen_string_literal: true

class QueueBackfillRunnerTypeAndShardingKeyIdOnCiRunnerManagers < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    # no-op
  end

  def down
    # no-op
  end
end
