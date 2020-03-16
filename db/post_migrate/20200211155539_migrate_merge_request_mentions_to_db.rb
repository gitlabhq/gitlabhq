# frozen_string_literal: true

class MigrateMergeRequestMentionsToDb < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY = 3.minutes.to_i
  BATCH_SIZE = 1_000
  MIGRATION = 'UserMentions::CreateResourceUserMention'

  JOIN = "LEFT JOIN merge_request_user_mentions on merge_requests.id = merge_request_user_mentions.merge_request_id"
  QUERY_CONDITIONS = "(description like '%@%' OR title like '%@%') AND merge_request_user_mentions.merge_request_id IS NULL"

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'
  end

  def up
    MergeRequest
      .joins(JOIN)
      .where(QUERY_CONDITIONS)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql('MIN(merge_requests.id)'), Arel.sql('MAX(merge_requests.id)')).first
      migrate_in(index * DELAY, MIGRATION, ['MergeRequest', JOIN, QUERY_CONDITIONS, false, *range])
    end
  end

  def down
    # no-op
  end
end
