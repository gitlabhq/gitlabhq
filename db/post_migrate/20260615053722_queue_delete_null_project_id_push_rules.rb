# frozen_string_literal: true

class QueueDeleteNullProjectIdPushRules < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "DeleteNullProjectIdPushRules"

  def up
    # no-op: This migration has been requeued for self-managed by
    # RequeueDeleteNullProjectIdPushRules so it runs after the NOT NULL
    # constraint on push_rules.project_id (20260715040848).
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/608164
  end

  def down
    # no-op: This migration has been requeued by RequeueDeleteNullProjectIdPushRules
  end
end
