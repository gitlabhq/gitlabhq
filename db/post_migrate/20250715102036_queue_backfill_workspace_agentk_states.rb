# frozen_string_literal: true

class QueueBackfillWorkspaceAgentkStates < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillWorkspaceAgentkStates"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  DELAY_INTERVAL = 2.minutes

  # @return [Void]
  def up
    # no-op because there was a bug in the original migration, which has been
    # fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203996
    nil
  end

  # @return [Void]
  def down
    # no-op because there was a bug in the original migration, which has been
    # fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203996
    nil
  end
end
