# frozen_string_literal: true

class QueueBackfillJiraTrackerDataShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  # re-enqueued via https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197199
  def up; end

  def down; end
end
