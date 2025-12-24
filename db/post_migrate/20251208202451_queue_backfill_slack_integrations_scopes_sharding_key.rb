# frozen_string_literal: true

class QueueBackfillSlackIntegrationsScopesShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillSlackIntegrationsScopesShardingKey"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 50

  def up
    # no-op
    # We are going to have to retry this BBM. More details in
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215658#note_2960239220
  end

  def down
    # no-op
  end
end
