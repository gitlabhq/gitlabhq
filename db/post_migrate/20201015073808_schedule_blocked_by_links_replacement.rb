# frozen_string_literal: true

class ScheduleBlockedByLinksReplacement < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 2.minutes
  # at the time of writing there were 47600 blocked_by issues:
  # estimated time is 48 batches * 2 minutes -> 100 minutes
  BATCH_SIZE = 1000
  MIGRATION = 'ReplaceBlockedByLinks'

  disable_ddl_transaction!

  class IssueLink < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issue_links'
  end

  def up
    # no-op
    # superseded by db/post_migrate/20201102073808_schedule_blocked_by_links_replacement_second_try.rb
  end

  def down
  end
end
