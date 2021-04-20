# frozen_string_literal: true

require 'set'

class ScheduleSyncBlockingIssuesCount < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  BATCH_SIZE = 50
  DELAY_INTERVAL = 120.seconds.to_i
  MIGRATION = 'SyncBlockingIssuesCount'

  disable_ddl_transaction!

  class TmpIssueLink < ActiveRecord::Base
    self.table_name = 'issue_links'

    include EachBatch
  end

  def up
    return unless Gitlab.ee?

    issue_link_ids = SortedSet.new

    TmpIssueLink.distinct.select(:source_id).where(link_type: 1).each_batch(of: 1000, column: :source_id) do |query|
      issue_link_ids.merge(query.pluck(:source_id))
    end

    TmpIssueLink.distinct.select(:target_id).where(link_type: 2).each_batch(of: 1000, column: :target_id) do |query|
      issue_link_ids.merge(query.pluck(:target_id))
    end

    issue_link_ids.each_slice(BATCH_SIZE).with_index do |items, index|
      start_id, *, end_id = items

      arguments = [start_id, end_id]

      final_delay = DELAY_INTERVAL * (index + 1)
      migrate_in(final_delay, MIGRATION, arguments)
    end
  end

  def down
    # NO OP
  end
end
