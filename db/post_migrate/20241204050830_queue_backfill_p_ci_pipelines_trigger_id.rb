# frozen_string_literal: true

class QueueBackfillPCiPipelinesTriggerId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    # no-op
    # see RequeueBackfillPCiPipelinesTriggerId
  end

  def down
    # no-op
  end
end
