# frozen_string_literal: true

class MigrateAllMergeRequestUserMentionsToDb < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY = 2.minutes.to_i
  BATCH_SIZE = 100_000
  MIGRATION = 'UserMentions::CreateResourceUserMention'

  JOIN = "LEFT JOIN merge_request_user_mentions on merge_requests.id = merge_request_user_mentions.merge_request_id"
  QUERY_CONDITIONS = "(description LIKE '%@%' OR title LIKE '%@%') AND merge_request_user_mentions.merge_request_id IS NULL"

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch
  end

  def up
    delay = DELAY

    MergeRequest.each_batch(of: BATCH_SIZE) do |batch, _|
      range = batch.pluck('MIN(merge_requests.id)', 'MAX(merge_requests.id)').first
      records_count = MergeRequest.joins(JOIN).where(QUERY_CONDITIONS).where(id: range.first..range.last).count

      if records_count > 0
        migrate_in(delay, MIGRATION, ['MergeRequest', JOIN, QUERY_CONDITIONS, false, *range])
        delay += [DELAY, (records_count / 500 + 1).minutes.to_i].max
      end
    end
  end

  def down
    # no-op
  end
end
