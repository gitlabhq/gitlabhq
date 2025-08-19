# frozen_string_literal: true

class RequeueBackfillNamespacesRedirectRoutesNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillNamespacesRedirectRoutesNamespaceId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  MAX_BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 250

  def up
    # NOOP because we need to requeue this BBM as some records remain (https://postgres.ai/console/gitlab/gitlab-production-main/sessions/41950/commands/128689)
  end

  def down
    # NOOP because we need to requeue this BBM as some records remain (https://postgres.ai/console/gitlab/gitlab-production-main/sessions/41950/commands/128689)
  end
end
